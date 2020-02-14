#!/bin/bash 

set -exuo pipefail

echo "Generate a kubeconfig file suitable for authenticating as the admin user"
cd cert/
KUBERNETES_PUBLIC_ADDRESS=$( cat ../terraform/elb.txt)

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way

count=$(kubectl get componentstatuses | tail -n +2 | grep Healthy | wc -l)
if ! [[ $count -eq 5 ]]; then
  echo "Controller Plane is not healthy"
  exit 1
fi

count=$(kubectl get nodes | tail -n +2 | grep Ready | wc -l)
if ! [[ $count -eq 3 ]]; then
  echo "Node is not healthy"
  exit 1
fi
