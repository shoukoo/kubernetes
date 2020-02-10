#!/bin/bash 

set -exuo pipefail

echo "Setting AWS Region to ap-southeast-2"
AWS_REGION=ap-southeast-2

if ! [ -x "$(command -v cfssl)" ]; then
  echo "Missing cfssl"
fi


if ! [ -x "$(command -v kubectl)" ]; then
  echo "Missing kubectl"
fi

if [ -z ${AWS_REGION} ]; then 
  echo "Missing AWS_REGION env varialbe"
fi

echo "Kill terraform"
cd terraform && terraform destroy \
  -var "region=${AWS_REGION}" \
  --auto-approve
