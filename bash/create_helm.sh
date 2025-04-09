#!/bin/bash




# Create Chart.yaml for model-service
echo "Creating Chart.yaml for model-service..."
cat > kubernetes/model-service/Chart.yaml << EOF
apiVersion: v2
name: model-service
description: A Helm chart for the OCR Model Service
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# Create Chart.yaml for gateway-service
echo "Creating Chart.yaml for gateway-service..."
cat > kubernetes/gateway-service/Chart.yaml << EOF
apiVersion: v2
name: gateway-service
description: A Helm chart for the OCR Gateway Service
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# Create parent chart directory
echo_green "Creating parent helm chart..."
mkdir -p kubernetes/ocr-system
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

# Create values.yaml for the parent chart
cat > kubernetes/ocr-system/values.yaml << EOF
model-service:
  replicaCount: 1
  image:
    repository: yourusername/ocr-model-service
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
    repository: yourusername/ocr-gateway-service
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

# Update model-service values.yaml
echo "Updating model-service values.yaml..."
cat > kubernetes/model-service/values.yaml << EOF
replicaCount: 1

image:
  repository: yourusername/ocr-model-service
  pullPolicy: IfNotPresent
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

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
EOF

# Update gateway-service values.yaml
echo "Updating gateway-service values.yaml..."
cat > kubernetes/gateway-service/values.yaml << EOF
replicaCount: 1

image:
  repository: yourusername/ocr-gateway-service
  pullPolicy: IfNotPresent
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

service:
  type: NodePort
  port: 8001

configMap:
  kserveUrl: "http://ocr-model-service:8080/v2/models/ocr-model/infer"

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

echo "Creating namespace for OCR system..."
kubectl create namespace ocr-system --dry-run=client -o yaml | kubectl apply -f -

