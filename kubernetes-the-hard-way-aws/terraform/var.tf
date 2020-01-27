variable image_id {
  type = string
}

variable region {
  type = string
}

variable controller_ips {
  type    = list(string)
  default = ["10.240.0.10", "10.240.0.11", "10.240.0.12"]
}

variable worker_ips {
  type    = list(string)
  default = ["10.240.0.20", "10.240.0.21", "10.240.0.22"]
}

provider aws {
  region  = var.region
  profile = "production"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu/images/hvm-ssd/ubuntu-bionic-18.04.*"
  owners      = ["099720109477"] // Owned by Canonical

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
