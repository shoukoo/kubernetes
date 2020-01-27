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

echo "Getting Image ID"
IMAGE_ID=$(aws --region $AWS_REGION ec2 describe-images --owners 099720109477 \
  --filters \
  'Name=root-device-type,Values=ebs' \
  'Name=architecture,Values=x86_64' \
  'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*' \
  | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')

echo "Kill terraform"
cd terraform && terraform destroy \
  -var "region=${AWS_REGION}" \
  -var "image_id=${IMAGE_ID}" \
  --auto-approve
