#!/bin/bash


# Ensure the namespace exists
echo "Creating namespace for OCR system..."
kubectl create namespace ocr-system --dry-run=client -o yaml | kubectl apply -f -

# Create parent Helm chart directory if it doesn't exist
if [ ! -d "kubernetes/ocr-system" ]; then
  echo "Creating parent Helm chart directory..."
  mkdir -p kubernetes/ocr-system
  
  # Create Chart.yaml
  cat > kubernetes/ocr-system/Chart.yaml << EOF
apiVersion: v2
name: ocr-system
description: A Helm chart for the complete OCR System
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: model-service
    version: 0.1.0
    repository: file://../model-service
  - name: gateway-service
    version: 0.1.0
    repository: file://../gateway-service
EOF

  # Create values.yaml
  cat > kubernetes/ocr-system/values.yaml << EOF
model-service:
  replicaCount: 1
  image:
    repository: nikila99/ocr-model-service
    tag: latest
  service:
    type: ClusterIP
    port: 8080
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi

gateway-service:
  replicaCount: 1
  image:
    repository: nikila99/ocr-gateway-service
    tag: latest
  configMap:
    kserveUrl: "http://ocr-model-service:8080/v2/models/ocr-model/infer"
  service:
    type: NodePort
    port: 8001
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      kubernetes.io/ingress.class: nginx
    hosts:
      - host: ocr.local
        paths:
          - path: /
            pathType: Prefix
  resources:
    limits:
      cpu: 300m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
EOF
fi

# Update  parent chart
echo "Updating Helm dependencies..."
cd kubernetes/ocr-system && helm dependency update && cd ../..

# Install or upgrade the Helm chart
echo "Installing/upgrading OCR system Helm chart..."
helm upgrade --install ocr-system kubernetes/ocr-system --namespace ocr-system

# Wait for deployments to be ready
kubectl -n ocr-system wait --for=condition=available --timeout=300s deployment --all

# Get service URLs
echo "\n=== Access Information ==="
MODEL_URL=$(kubectl get service -n ocr-system -l app.kubernetes.io/name=model-service -o jsonpath='{.items[0].spec.clusterIP}:{.items[0].spec.ports[0].port}')
echo "OCR Model Service (internal): ${MODEL_URL}"

