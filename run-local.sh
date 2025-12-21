#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
HELM_PATH="helm/hello-world"
IMAGE_REPO="guy66bp/hello-world-app"
IMAGE_TAG="latest"
APP_SECRET="local-secret"
INGRESS_HOST="hello.local"

# (Optional: Detect if minikube is running and enable ingress/tunnel)
minikube start
minikube addons enable ingress

# RUN THIS IN A SEPARATE TERMINAL:
# minikube tunnel

echo "Add to /etc/hosts: 127.0.0.1 $INGRESS_HOST"

helm upgrade --install "$PROJECT_NAME" "$HELM_PATH" \
  --set image.repository="$IMAGE_REPO" \
  --set image.tag="$IMAGE_TAG" \
  --set secrets.app_secret="$APP_SECRET" \
  --set ingress.enabled=true \
  --set ingress.host="$INGRESS_HOST"
