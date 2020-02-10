#!/bin/bash 

set -exuo pipefail
external_ip=$(aws ec2 --region=${AWS_REGION} describe-instances \
  --filters "Name=tag:Name,Values=controller-0" \
  --output text --query 'Reservations[].Instances[].PublicIpAddress')

scp -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  server_cluster_role.sh ubuntu@$external_ip:~/

ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  ubuntu@$external_ip bash server_cluster_role.sh

KUBERNETES_PUBLIC_ADDRESS=$(cat terraform/elb.txt)
pf=$(curl -k --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version | jq -r .platform)

echo $pf
if [[ "$pf" != "linux/amd64" ]]; then 
  echo "Unable to assign permission"
  exit 1
fi


