#!/bin/bash

CLUSTER_NAME="demo-eks"
VERSION="v2.7.1"

# Install CertManager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml

# Install CRDs
kubectl apply -k "github.com/kubernetes-sigs/aws-load-balancer-controller/config/crd?ref=${VERSION}"

# Install the controller
kubectl apply -k "github.com/kubernetes-sigs/aws-load-balancer-controller/config/default?ref=${VERSION}"

# Patch the deployment with the cluster name
kubectl -n kube-system patch deployment aws-load-balancer-controller \
  --type=json \
  -p="[{'op': 'add', 'path': '/spec/template/spec/containers/0/args/-', 'value': '--cluster-name=${CLUSTER_NAME}'}]"

# Verify
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system
