#!/bin/bash
helm repo add cilium https://helm.cilium.io/
helm repo update
export KUBERNETES_API_SERVER_ADDRESS=10.29.0.2
export KUBERNETES_API_SERVER_PORT=6443

helm template cilium cilium/cilium \
    --version 1.11.2 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost="${KUBERNETES_API_SERVER_ADDRESS}" \
    --set k8sServicePort="${KUBERNETES_API_SERVER_PORT}" >cilium.yaml

sed -i -e 's/^/        /' cilium.yaml # adds spaces
