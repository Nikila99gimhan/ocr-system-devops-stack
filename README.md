
# 🧠 OCR Microservice System - DevOps Implementation

This project implements a scalable **OCR (Optical Character Recognition)** system using two microservices deployed on Kubernetes, leveraging DevOps best practices.

---

## 🧩 System Architecture

```
[User] ---> [FastAPI Gateway Service] ---> [KServe Model Service (Tesseract)]
```

---

## 🛠️ Tech Stack

- **Containerization**: Docker (Multi-stage builds)
- **Orchestration**: Kubernetes
- **CI/CD**: GitOps with ArgoCD
- **Monitoring**: Prometheus + Grafana
- **Infrastructure as Code**: Helm & Kubernetes Manifests

---

## 📁 Project Structure

```
.
├── api-gateway.py               # FastAPI service for image upload & request forwarding
├── model.py                     # OCR model endpoint using KServe & Tesseract
├── pyproject.toml / poetry.lock # Python dependency management with Poetry
├── dockerfiles/
│   ├── Dockerfile.gateway       # Gateway Dockerfile
│   └── Dockerfile.model         # Model Dockerfile
├── bash/                        # Automation scripts
│   ├── docker_builds.sh         # Docker build commands
│   ├── argocd_setup.sh          # ArgoCD setup script
│   ├── create_helm.sh           # Helm chart scaffolding
│   ├── deploy_helm.sh           # Helm chart deployment
│   ├── deploy_argocd.sh         # GitOps deployment via ArgoCD
│   └── setup_monitoring.sh      # Monitoring stack installation
├── kubernetes/
│   ├── argocd/                  # ArgoCD CRDs (App & Project)
│   ├── gateway-service/         # Helm chart for Gateway
│   ├── model-service/           # Helm chart for Model
│   └── ocr-system/              # Parent Helm chart combining both
├── monitoring/
│   └── ocr-dashboard.json       # Grafana dashboard for OCR metrics
├── docs/
│   └── architecture-diagram.svg # Visual architecture
└── README.md                    # This file
```

---

## 🚀 Step-by-Step Deployment Guide

### ✅ 1. Local Development

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Install dependencies
poetry install

# Run services locally
poetry run python model.py &
poetry run python api-gateway.py &

# Test OCR Endpoint
curl -X POST -F "image_file=@img.png" http://localhost:8001/gateway/ocr
```

---

### 🐳 2. Docker Containerization

```bash
chmod +x bash/docker_builds.sh
./bash/docker_builds.sh
```

**Multi-stage Build Highlights:**

- Base image: `python:3.11-slim`
- Build & runtime separation
- Security-hardened with minimized layers

---

### 🧪 Docker Testing

```bash
docker network create ocr-network

docker run -d --name ocr-model-service --network ocr-network -p 8080:8080 nikila99/ocr-model-service:latest

docker run -d --name ocr-gateway-service \
  --network ocr-network \
  -e KSERVE_URL="http://ocr-model-service:8080/v2/models/ocr-model/infer" \
  -p 8001:8001 nikila99/ocr-gateway-service:latest

# Test the system
curl -X POST -F "image_file=@img.png" http://localhost:8001/gateway/ocr
```

---

### ☸️ 3. Kubernetes Infrastructure Setup

```bash
minikube start --driver=docker --cpus=2 --memory=4g

minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress
```

---

### 📦 4. Helm Deployment

#### Option 1: Helm (Manual)

```bash
chmod +x bash/create_helm.sh
./bash/create_helm.sh

# Ensure Docker Hub image names are updated in values.yaml
chmod +x bash/deploy_helm.sh
./bash/deploy_helm.sh
```

> The `ocr-system` chart is the parent; `gateway-service` and `model-service` are subcharts for modular deployment.

---

### 🔁 5. GitOps Deployment with ArgoCD

```bash
chmod +x bash/argocd_setup.sh
./bash/argocd_setup.sh

kubectl apply -f kubernetes/argocd/project.yaml
kubectl apply -f kubernetes/argocd/application.yaml
```

**ArgoCD CRDs:**

- `AppProject`: Controls source repos & target clusters
- `Application`: Defines app source & deployment config

> In production, this setup ensures auto-sync with Git for all infrastructure and app changes.

---

### 📊 6. Monitoring with Prometheus + Grafana

```bash
chmod +x bash/setup_monitoring.sh
./bash/setup_monitoring.sh
```

#### Access Dashboards

```bash
minikube service prometheus-server -n monitoring
minikube service grafana -n monitoring
minikube service argocd-server -n argocd
```

> Use the provided `ocr-dashboard.json` to import the pre-built Grafana dashboard.

---

## ✅ Key Benefits

- 🔁 **GitOps Workflow**: Declarative, version-controlled, auto-synced infrastructure
- 🐳 **Lightweight Containers**: Secure and optimized multi-stage Docker builds
- ☁️ **Scalable Deployment**: Helm charts enable modular and repeatable Kubernetes deployments
- 📈 **Observability**: Real-time model performance monitoring with Prometheus & Grafana

---

## 🧠 Grafana

#### ✅ Enable Prometheus Scraping on the Model Service

To allow Prometheus to scrape metrics from the OCR model service, apply the necessary annotations to the Kubernetes deployment:

```bash
kubectl patch deployment ocr-system-model-service -n ocr-system --type=json -p='[
  {"op": "add", "path": "/spec/template/metadata/annotations", "value": {
    "prometheus.io/scrape": "true",
    "prometheus.io/port": "8080",
    "prometheus.io/path": "/metrics"
  }}
]'
```

This command adds the required annotations:

- `prometheus.io/scrape`: Enables Prometheus scraping
- `prometheus.io/port`: Sets the port to scrape (default `8080`)
- `prometheus.io/path`: Path to the metrics endpoint (`/metrics`)

> ⚠️ If the annotations already exist, Kubernetes may return `patched (no change)` — which is expected.

---

#### 📊 Automatically Import Grafana Dashboard

A pre-built Grafana dashboard JSON (`ocr-dashboard.json`) is included under the `monitoring/` directory. To automate the dashboard import process, a shell script `import_dashboard.sh` is provided.

**Steps to apply the dashboard:**

1. Make the script executable:

   ```bash
   chmod +x bash/import_dashboard.sh
   ```

2. Run the script:
   ```bash
   ./bash/import_dashboard.sh
   ```

This script uses the Grafana HTTP API to upload the dashboard and make it available instantly on your Grafana instance.

> 🔐 Ensure your script contains correct Grafana credentials and URL (`http://localhost:<grafana-port>`) for the import to succeed.

---

#### 🔍 Access Monitoring Interfaces via Minikube

```bash
minikube service prometheus-server -n monitoring
minikube service grafana -n monitoring
```

- **Grafana** will be available at the exposed URL. Default credentials are:

  - Username: `admin`
  - Password: `admin` (or as set in your Helm values)

- **Prometheus** UI allows you to query and validate scraped metrics.

---

This monitoring setup gives you a full observability stack to:

- Track performance metrics (inference time, request rates, etc.)
- Visualize trends using Grafana dashboards
- Troubleshoot service issues using live metrics

## 📌 Notes

- ArgoCD was used for GitOps configuration but actual deployment was via Helm to meet assignment guidelines.
- GitOps flow is production-ready and can easily be activated with Git integration.

---
