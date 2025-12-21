#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
IMAGE_NAME="hello-world-app:local"
HELM_PATH="helm/hello-world"
INGRESS_HOST="hello.local"
APP_SECRET=$(openssl rand -hex 16 2>/dev/null || echo "local-secret")

echo "===[ 1. Checking dependencies ]==="
for dep in minikube helm docker; do
  if ! command -v $dep &>/dev/null; then
    echo "Error: '$dep' is not installed. Please install it first."
    exit 1
  fi
done

echo "===[ 2. Starting minikube ]==="
minikube start

echo "===[ 3. Setting Docker env to Minikube ]==="
eval $(minikube docker-env)

echo "===[ 4. Building the Docker image ]==="
docker build -t "$IMAGE_NAME" ./app

echo "===[ 5. Enabling Ingress addon in Minikube ]==="
minikube addons enable ingress

echo "===[ 6. Deploying the Helm chart (local values) ]==="
helm upgrade --install "$PROJECT_NAME" "$HELM_PATH" \
  --set image.repository="$IMAGE_NAME" \
  --set image.tag=latest \
  --set ingress.host="$INGRESS_HOST" \
  --set secrets.app_secret="$APP_SECRET"

echo "===[ 7. Waiting for Ingress controller and app pod... ]==="
# Wait for ingress and pods ready
kubectl rollout status deployment "$PROJECT_NAME" --timeout=120s
kubectl wait --namespace kube-system --for=condition=Ready pod -l app.kubernetes.io/name=ingress-nginx --timeout=120s 2>/dev/null || true
kubectl wait --namespace kube-system --for=condition=Ready pod -l k8s-app=ingress-nginx --timeout=120s 2>/dev/null || true

echo "===[ 8. Configuring /etc/hosts (requires sudo or manual edit) ]==="
HOSTS_LINE="127.0.0.1 $INGRESS_HOST"
if ! grep -q "$INGRESS_HOST" /etc/hosts; then
  echo "Adding '$HOSTS_LINE' to /etc/hosts (will request your password)"
  if [ "$(id -u)" -eq 0 ]; then
    echo "$HOSTS_LINE" >>/etc/hosts
  else
    sudo sh -c "echo '$HOSTS_LINE' >> /etc/hosts"
  fi
else
  echo "'$INGRESS_HOST' already present in /etc/hosts"
fi

echo "===[ 9. Exposing the app via Minikube tunnel (in background) ]==="
(minikube tunnel > /dev/null 2>&1 &)
sleep 3

echo
echo "=================================================================="
echo "🚀 Done! Try opening http://$INGRESS_HOST/ in your browser."
echo "If you see ERR_CONNECTION_REFUSED, the tunnel may not be ready yet."
echo
echo "Note: To delete resources:"
echo "  helm uninstall $PROJECT_NAME"
echo "  minikube stop"
echo "=================================================================="
