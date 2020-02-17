#!/bin/bash 

set -exuo pipefail

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 --region=${AWS_REGION} describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    server_etcd.sh ubuntu@$external_ip:~/

  ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ubuntu@$external_ip bash server_etcd.sh

  # verifying etcd is installed on all the controller servers
  if [ ${instance} == "controller-2" ]; then
    ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ubuntu@$external_ip <<'EOF'
        set -ex
        controllers=$(sudo ETCDCTL_API=3 etcdctl member list \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/etcd/ca.pem \
        --cert=/etc/etcd/kubernetes.pem \
        --key=/etc/etcd/kubernetes-key.pem) 

        echo $controllers | grep controller-0 
        echo $controllers | grep controller-1 
        echo $controllers | grep controller-2 
        
        echo "SUCCESS: installed etcd on controller 0, 1 and 2"
EOF
  fi

done
