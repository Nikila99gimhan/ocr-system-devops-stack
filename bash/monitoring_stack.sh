#!/bin/bash

# First create a separate namespace for all monitoring tools
kubectl create namespace monitoring

# Add the helm repos we need
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
echo "Setting up Prometheus..."
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.service.type=NodePort \
  --set server.resources.limits.cpu=300m \
  --set server.resources.limits.memory=512Mi \
  --set alertmanager.resources.limits.cpu=100m \
  --set alertmanager.resources.limits.memory=256Mi

# Give Prometheus some time to start up
echo "Waiting for Prometheus to start..."
kubectl wait --for=condition=available --timeout=180s deployment/prometheus-server -n monitoring

# Now install Grafana
echo "Setting up Grafana..."
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set service.type=NodePort \
  --set resources.limits.cpu=200m \
  --set resources.limits.memory=256Mi

# Wait for Grafana pods to be ready
echo "Waiting for Grafana to start..."
kubectl wait --for=condition=available --timeout=180s deployment/grafana -n monitoring

# Get the admin password for Grafana
echo "Your Grafana admin password is:"
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo

# Print the service URLs
echo "Access Prometheus at:"
minikube service prometheus-server -n monitoring --url

echo "Access Grafana at:"
minikube service grafana -n monitoring --url
echo "Log in with username: admin and the password shown above"