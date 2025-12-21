#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
IMAGE_NAME="hello-world-app:local"
HELM_PATH="helm/hello-world"
INGRESS_HOST="hello.local"
APP_SECRET=$(openssl rand -hex 16 2>/dev/null || echo "local-secret")

print_header() {
  echo
  echo "===[ $1 ]==="
}

install_minikube() {
  print_header "Installing minikube"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install minikube
    else
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
      sudo install minikube-darwin-amd64 /usr/local/bin/minikube
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      sudo install minikube-linux-amd64 /usr/local/bin/minikube
    else
      echo "Please install minikube manually: https://minikube.sigs.k8s.io/docs/start/"
      exit 1
    fi
  else
    echo "Please install minikube manually: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
  fi
}

install_helm() {
  print_header "Installing helm"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install helm
    else
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
      curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
      sudo apt-get install apt-transport-https --yes
      echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
      sudo apt-get update
      sudo apt-get install helm
    else
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
  else
    echo "Please install helm manually: https://helm.sh/docs/intro/install/"
    exit 1
  fi
}

install_docker() {
  print_header "Docker is required. Please follow the manual install guide."
  echo "Visit: https://docs.docker.com/get-docker/"
  exit 1
}

setup_dependency() {
  dep="$1"
  case $dep in
    minikube)
      if ! command -v minikube &>/dev/null; then
        install_minikube
      fi
      ;;
    helm)
      if ! command -v helm &>/dev/null; then
        install_helm
      fi
      ;;
    docker)
      if ! command -v docker &>/dev/null; then
        install_docker
      fi
      ;;
  esac
}

print_header "1. Checking dependencies and installing if missing"
for dep in minikube helm docker; do
  setup_dependency $dep
done

print_header "2. Starting minikube"
minikube start

print_header "3. Setting Docker env to Minikube"
eval $(minikube docker-env)

print_header "4. Building the Docker image"
docker build -t "$IMAGE_NAME" ./app

print_header "5. Enabling Ingress addon in Minikube"
minikube addons enable ingress

print_header "6. Deploying the Helm chart (local values)"
helm upgrade --install "$PROJECT_NAME" "$HELM_PATH" \
  --set image.repository="$IMAGE_NAME" \
  --set image.tag=latest \
  --set ingress.host="$INGRESS_HOST" \
  --set secrets.app_secret="$APP_SECRET"

print_header "7. Waiting for Ingress controller and app pod..."
kubectl rollout status deployment "$PROJECT_NAME" --timeout=120s
kubectl wait --namespace kube-system --for=condition=Ready pod -l app.kubernetes.io/name=ingress-nginx --timeout=120s 2>/dev/null || true
kubectl wait --namespace kube-system --for=condition=Ready pod -l k8s-app=ingress-nginx --timeout=120s 2>/dev/null || true

print_header "8. Configuring /etc/hosts (requires sudo or manual edit)"
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

print_header "9. Exposing the app via Minikube tunnel (in background)"
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
