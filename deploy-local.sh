#!/usr/bin/env bash
set -e

REQUIRED=("docker" "minikube" "kubectl" "helm")

for dep in "${REQUIRED[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    echo "ERROR: Please install '$dep' and ensure it is in your PATH before running this script."
    exit 1
  fi
done

header() { echo -e "\n===[ $1 ]===\n"; }

# Detect correct Minikube driver flag for compatibility
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

header "Enabling Ingress"
minikube addons enable ingress

header "Helm deploy"
helm upgrade --install "$PROJECT_NAME" "$CHART_PATH"

header "Waiting for app"
kubectl rollout status deployment/"$PROJECT_NAME" --timeout=120s

# Set up /etc/hosts for Ingress
HOST=hello.local
IP=$(minikube ip)
grep -q "$HOST" /etc/hosts || echo "$IP $HOST" | sudo tee -a /etc/hosts >/dev/null

echo -e "\n=================================================================="
echo "Your app is live at: http://$HOST"
echo "Press Enter to remove cleanup."
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

sudo sed -i "/[[:space:]]$HOST$/d" /etc/hosts && echo "Removed $HOST from /etc/hosts"
echo "Done!"
