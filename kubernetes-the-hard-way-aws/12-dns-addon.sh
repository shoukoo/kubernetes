#!/bin/bash 

# https://github.com/prabhatsharma/kubernetes-the-hard-way-aws/blob/master/docs/12-dns-addon.md
# In this lab you will deploy the DNS add-on which provides DNS based service discovery to applications running inside the Kubernetes cluster.

set -exuo pipefail

kubectl create -f core-dns.yaml

sleep 60
kubectl get pods -l k8s-app=kube-dns -n kube-system | grep Running
kubectl get pods -l k8s-app=kube-dns -n kube-system | grep "3/3"

# Running busybox
kubectl run busybox --image=busybox:1.28 --restart=Never -- sleep 3600

sleep 15
kubectl get pod busybox | grep Running
kubectl exec -it busybox -- nslookup kubernetes | grep 10.32.0.10
