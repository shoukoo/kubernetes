#!/bin/bash 

set -exuo pipefail

if ! [ -x "$(command -v cfssl)" ]; then
  echo "Missing cfssl"
fi


if ! [ -x "$(command -v kubectl)" ]; then
  echo "Missing kubectl"
fi

if [ -z ${AWS_REGION} ]; then 
  echo "Missing AWS_REGION env varialbe"
fi

echo "Generating a key pair"
ssh-keygen -b 2048 -t rsa -f key -q -N ""

echo "Appling terraform"
cd terraform && terraform apply \
  -var "region=${AWS_REGION}" \
  --auto-approve
