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
echo
echo "=================================================================="
echo "Your app will be accessible at a localhost URL while the proxy is open."
echo "Launching proxy... (ctrl+C or Enter to stop and clean up)"
echo

minikube service "$PROJECT_NAME" --url &

PROXY_PID=$!

# Give the proxy a moment to start and output the URL
sleep 2
SERVICE_URL=$(minikube service "$PROJECT_NAME" --url | head -n1)
echo "👉 Open this URL in your browser: $SERVICE_URL"
echo

echo "Press Enter to clean up and remove all local Kubernetes resources..."
read

# Kill the background proxy
kill $PROXY_PID || true

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

echo "Clean up complete!"
