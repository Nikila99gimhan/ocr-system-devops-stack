#!/bin/bash
# Script to install ArgoCD on Minikube

# Create namespace
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd

# Add Helm repository
echo "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD with resource limits for Minikube
echo "Installing ArgoCD..."
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=NodePort \
  --set controller.resources.limits.cpu=300m \
  --set controller.resources.limits.memory=512Mi \
  --set server.resources.limits.cpu=300m \
  --set server.resources.limits.memory=512Mi \
  --set repoServer.resources.limits.cpu=300m \
  --set repoServer.resources.limits.memory=512Mi

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the admin password
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# Get the ArgoCD URL
echo "ArgoCD URL:"
minikube service argocd-server -n argocd --url