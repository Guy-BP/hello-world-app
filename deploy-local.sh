#!/usr/bin/env bash
set -e

header() { echo -e "\n===[ $1 ]===\n"; }

REQUIRED=("docker" "minikube" "kubectl" "helm")
for dep in "${REQUIRED[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    echo "ERROR: Please install '$dep' and ensure it is in your PATH before running this script."
    exit 1
  fi
done

if minikube start --help 2>&1 | grep -q -- '--driver'; then
  DRIVER_FLAG="--driver=docker"
else
  DRIVER_FLAG="--vm-driver=docker"
fi

PROJECT_NAME="hello-app"
CHART_PATH="helm/hello-world"

header "Restarting Minikube"
minikube delete --profile=minikube &>/dev/null || true
minikube start $DRIVER_FLAG

header "Helm deploy"
helm upgrade --install "$PROJECT_NAME" "$CHART_PATH"

header "Waiting for app deployment"
kubectl rollout status deployment/"$PROJECT_NAME" --timeout=120s

header "Access your app"
# Get the NodePort and Minikube IP to output access URL
NODE_PORT=$(kubectl get svc "$PROJECT_NAME" -o=jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)
APP_URL="http://${MINIKUBE_IP}:${NODE_PORT}"
echo
echo "=================================================================="
echo "🚀 Done! Your app should be accessible at: $APP_URL"
echo "Open your browser and check!"
echo
echo "Press Enter to clean up and remove all local Kubernetes resources..."
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

echo "Clean up complete!"
