#!/bin/bash


DOCKER_USERNAME="nikila99"

# Build the KServe 
echo "Building KServe model service image..."
docker build -t ${DOCKER_USERNAME}/ocr-model-service:latest -f dockerfiles/Dockerfile.model .

# Build the FastAPI gateway 
echo "Building FastAPI gateway service image..."
docker build -t ${DOCKER_USERNAME}/ocr-gateway-service:latest -f dockerfiles/Dockerfile.gateway .

echo "Docker images built successfully!"