#!/bin/bash 

# https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/12-dns-addon.md
# In this lab you will deploy the DNS add-on which provides DNS based service discovery to applications running inside the Kubernetes cluster.

set -exuo pipefail

# Create secret
#kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata"
#
#kubectl create deployment nginx --image=nginx
#sleep 15
#kubectl get pods -l app=nginx | grep Running
#kubectl get pods -l app=nginx | grep 1/1
#
#kubectl exec -ti $POD_NAME -- nginx -v | grep "nginx version"
#
#
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

# Expose port 
#kubectl expose deployment nginx --port 80 --type NodePort
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

SECURITY_GROUP_ID=$(cat terraform/sg.txt)
aws --region=${AWS_REGION} ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port ${NODE_PORT} \
  --cidr 0.0.0.0/0

INSTANCE_NAME=$(kubectl get pod $POD_NAME --output=jsonpath='{.spec.nodeName}')

EXTERNAL_IP=$(aws --region=${AWS_REGION} ec2 describe-instances \
    --filters "Name=network-interface.private-dns-name,Values=${INSTANCE_NAME}.${AWS_REGION}.compute.internal" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

curl -I http://${EXTERNAL_IP}:${NODE_PORT} | grep "200 OK"
