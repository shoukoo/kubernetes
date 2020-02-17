#!/bin/bash 

set -exuo pipefail

cd cert
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF


for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws --region=${AWS_REGION} ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i ../key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    encryption-config.yaml ubuntu@${external_ip}:~/
done
