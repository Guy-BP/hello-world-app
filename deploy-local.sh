#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
CHART_PATH="helm/hello-world"
AUTO_INSTALLED=()

header() { echo -e "\n===[ $1 ]===\n"; }

auto_install() {
  local bin="$1"
  if command -v $bin &>/dev/null; then return; fi
  echo "Installing $bin..."
  case "$bin" in
    kubectl)
      local LATEST=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
      curl -Lo kubectl "https://storage.googleapis.com/kubernetes-release/release/${LATEST}/bin/linux/amd64/kubectl"
      chmod +x kubectl && sudo mv kubectl /usr/local/bin/
      ;;
    minikube)
      local VER=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep tag_name | cut -d '"' -f 4)
      curl -Lo minikube "https://storage.googleapis.com/minikube/releases/${VER}/minikube-linux-amd64"
      chmod +x minikube && sudo mv minikube /usr/local/bin/
      ;;
    docker)
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh; rm -f get-docker.sh
      ;;
    helm)
      local VER=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
      curl -LO "https://get.helm.sh/helm-${VER}-linux-amd64.tar.gz"
      tar -xzf "helm-${VER}-linux-amd64.tar.gz"
      sudo mv linux-amd64/helm /usr/local/bin/helm
      rm -rf "helm-${VER}-linux-amd64.tar.gz" linux-amd64
      ;;
    *)
      echo "Unknown binary: $bin"; exit 1 ;;
  esac
  AUTO_INSTALLED+=("$bin")
}

header "Checking/installing dependencies"
for dep in docker minikube kubectl helm; do auto_install "$dep"; done

# Detect correct Minikube driver flag for compatibility
if minikube start --help 2>&1 | grep -q -- '--driver'; then
  DRIVER_FLAG="--driver=docker"
else
  DRIVER_FLAG="--vm-driver=docker"
fi

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
echo "Press Enter to remove everything."
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

for bin in "${AUTO_INSTALLED[@]}"; do
  sudo rm -f "/usr/local/bin/$bin" 2>/dev/null || true
  echo "Removed: $bin"
done

sudo sed -i "/[[:space:]]$HOST$/d" /etc/hosts && echo "Removed $HOST from /etc/hosts"
echo "Done!"
