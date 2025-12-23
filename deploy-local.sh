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

header "Enabling Ingress"
minikube addons enable ingress

header "Waiting for Ingress NGINX controller pod to be ready ..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s

header "Waiting for Ingress admission webhook to be reported ready ..."
for i in {1..60}; do
  ENDPOINT=$(kubectl get endpoints ingress-nginx-controller-admission -n ingress-nginx -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)
  if [[ -n "$ENDPOINT" ]]; then
    # Check TCP 443 connectivity (ignore self-signed certs)
    set +e
    timeout 2 bash -c "echo > /dev/tcp/$ENDPOINT/443" 2>/dev/null
    CONNECTED=$?
    set -e
    if [[ $CONNECTED -eq 0 ]]; then
      echo "Ingress admission webhook endpoint $ENDPOINT:443 is accepting connections."
      break
    else
      echo "Waiting for TCP connect to $ENDPOINT:443 ... ($i/60)"
    fi
  else
    echo "Waiting for endpoint IP ... ($i/60)"
  fi
  sleep 2
  if [[ $i -eq 60 ]]; then
    echo "ERROR: Timed out waiting for admission webhook endpoint to be ready."
    exit 1
  fi
done

header "Helm deploy"
helm upgrade --install "$PROJECT_NAME" "$CHART_PATH"

header "Waiting for app deployment"
kubectl rollout status deployment/"$PROJECT_NAME" --timeout=120s

header "Access your app"
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc "$PROJECT_NAME" -o=jsonpath='{.spec.ports[0].nodePort}')
APP_URL="http://${MINIKUBE_IP}:${NODE_PORT}"
echo
echo "=================================================================="
echo "🚀 Done! Your app should be accessible at: $APP_URL"
echo "(Minikube Docker driver: use this address, not 127.0.0.1, in your Windows browser)"
echo "Open your browser and check!"
echo
echo "Press Enter to clean up and remove all local Kubernetes resources..."
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

echo "Clean up complete!"
