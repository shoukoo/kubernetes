#!/bin/bash 

# https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/12-dns-addon.md
# In this lab you will deploy the DNS add-on which provides DNS based service discovery to applications running inside the Kubernetes cluster.

set -exuo pipefail

kubectl create -f core-dns.yaml

for i in $( kubectl get nodes -o name | cut -d / -f 2); do
  kubectl label nodes $i kubernetes.io/os=linux
done

kubectl get pods -l k8s-app=kube-dns -n kube-system

