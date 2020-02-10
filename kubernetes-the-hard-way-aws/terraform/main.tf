resource aws_vpc main {
  cidr_block = "10.240.0.0/24"
  tags = {
    Name = "kubernetes-the-hard-way"
  }
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource aws_subnet main {
  availability_zone = "ap-southeast-2b"
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.240.0.0/24"

  tags = {
    Name = "kubernetes"
  }
}

resource aws_internet_gateway main {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "kubernetes"
  }
}


resource aws_route_table main {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "kubernetes"
  }
}

resource aws_main_route_table_association main {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
}

resource aws_security_group main {
  name        = "kubernetes"
  description = "kubernetes security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "kubernetes"
  }

  ingress {
    protocol    = "-1"
    to_port     = "0"
    from_port   = "0"
    cidr_blocks = ["10.240.0.0/24", "10.200.0.0/16"]
  }


  ingress {
    protocol    = "tcp"
    to_port     = "22"
    from_port   = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    to_port     = "80"
    from_port   = "80"
    cidr_blocks = ["0.0.0.0/0"]
  }



  ingress {
    protocol    = "tcp"
    to_port     = "6443"
    from_port   = "6443"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "icmp"
    to_port     = "0"
    from_port   = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource aws_key_pair main {
  key_name   = "kubernetes"
  public_key = file("../key.pub")
}


resource aws_instance controller {
  count                       = length(var.controller_ips)
  associate_public_ip_address = true
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = "kubernetes"
  vpc_security_group_ids      = [aws_security_group.main.id]
  private_ip                  = element(var.controller_ips, count.index)
  instance_type               = "t3.micro"
  user_data                   = "name=controller-${count.index}"
  subnet_id                   = aws_subnet.main.id
  source_dest_check           = false
  iam_instance_profile        = aws_iam_instance_profile.main.id

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  tags = {
    Name = "controller-${count.index}"
  }
}

resource aws_instance worker {
  count                       = length(var.worker_ips)
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  key_name                    = "kubernetes"
  vpc_security_group_ids      = [aws_security_group.main.id]
  instance_type               = "t3.micro"
  private_ip                  = element(var.worker_ips, count.index)
  user_data                   = "name=worker-${count.index}|pod-cidr=10.200.${count.index}.0/24"
  subnet_id                   = aws_subnet.main.id
  source_dest_check           = false
  iam_instance_profile        = aws_iam_instance_profile.main.id


  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  tags = {
    Name = "worker-${count.index}"
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "kubernetes"
  role = aws_iam_role.main.id
}

resource "aws_iam_role" "main" {
  name = "kubernetes"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": ["ec2.amazonaws.com"]
             },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

}

resource "aws_iam_role_policy" "tagging" {
  name = "describe_instance_tags"
  role = aws_iam_role.main.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action":[
        "ec2messages:GetMessages",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
        "ssm:*",
        "ec2:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeImages"
      ],
      "Effect": "Allow",
      "Resource":"*"
    }
  ]
}
EOF
}

resource aws_lb main {
  name               = "kubernetes"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.main.id]
  provisioner "local-exec" {
    command = "touch elb.txt && echo ${aws_lb.main.dns_name} > elb.txt"
  }
}

resource aws_lb_target_group main {
  name     = "kubernetes"
  protocol = "TCP"
  port     = 6443
  vpc_id   = aws_vpc.main.id
}

resource aws_lb_target_group_attachment main {
  count            = length(var.controller_ips)
  target_group_arn = aws_lb_target_group.main.id
  target_id        = element(aws_instance.controller.*.id, count.index)
}

resource aws_lb_listener main {
  protocol          = "TCP"
  load_balancer_arn = aws_lb.main.arn
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

