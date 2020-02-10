#!/bin/bash 

#
# Kubernetes API Server to access the Kubelet API on each worker node.
# Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

set -exuo pipefail

# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the 
# Kubelet API and perform most common tasks associated with managing pods:
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

# The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the 
# client certificate as defined by the --kubelet-client-certificate flag.
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
