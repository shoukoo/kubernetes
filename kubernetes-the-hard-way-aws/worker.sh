#!/bin/bash 

set -exuo pipefail

#for instance in worker-0 worker-1 worker-2; do
#  external_ip=$(aws --region=${AWS_REGION} ec2 describe-instances \
#    --filters "Name=tag:Name,Values=${instance}" \
#    --output text --query 'Reservations[].Instances[].PublicIpAddress')
#
#  scp -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
#    server_worker.sh ubuntu@$external_ip:~/
#
#  ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
#    ubuntu@$external_ip bash server_worker.sh
#done
#
external_ip=$(aws --region=${AWS_REGION} ec2 describe-instances \
    --filters "Name=tag:Name,Values=controller-0" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  ubuntu@$external_ip << 'EOF'
    count=$(kubectl get nodes --kubeconfig admin.kubeconfig | grep "Ready" | wc -l)
    if ! [[ $count -eq 3 ]]; then 
      echo "Worker node is not healthy"
    fi
EOF
