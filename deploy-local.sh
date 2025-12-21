#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
HELM_PATH="helm/hello-world"
IMAGE_REPO="guy66bp/hello-world-app"
IMAGE_TAG="latest"
AUTO_INSTALLED=()

header() { echo -e "\n===[ $1 ]===\n"; }

wait_until_ready() {
  local cmd="$1"
  local waited=0
  until $cmd version &>/dev/null || [ $waited -ge 10 ]; do
    sleep 1
    waited=$((waited + 1))
  done
}

auto_install() {
  local bin="$1"
  if command -v $bin &>/dev/null; then
    return
  fi
  echo "$bin not found. Auto-installing temporarily..."

  case "$bin" in
    kubectl)
      LATEST=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
      curl -Lo kubectl "https://storage.googleapis.com/kubernetes-release/release/${LATEST}/bin/linux/amd64/kubectl"
      chmod +x kubectl
      sudo mv kubectl /usr/local/bin/kubectl
      sleep 2
      wait_until_ready /usr/local/bin/kubectl
      AUTO_INSTALLED+=("kubectl")
      ;;
    minikube)
      curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      chmod +x minikube
      sudo mv minikube /usr/local/bin/minikube
      sleep 2
      AUTO_INSTALLED+=("minikube")
      ;;
    docker)
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      rm -f get-docker.sh
      sleep 2
      AUTO_INSTALLED+=("docker")
      ;;
    helm)
      HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
      curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
      tar -xzf "helm-${HELM_VERSION}-linux-amd64.tar.gz"
      sudo mv linux-amd64/helm /usr/local/bin/helm
      rm -rf "helm-${HELM_VERSION}-linux-amd64.tar.gz" linux-amd64
      sleep 2
      wait_until_ready /usr/local/bin/helm
      AUTO_INSTALLED+=("helm")
      ;;
    *)
      echo "Unknown binary: $bin"
      exit 1
      ;;
  esac
}

header "Checking and auto-installing dependencies if needed (docker, minikube, helm, kubectl)"
auto_install docker
auto_install minikube
auto_install kubectl
auto_install helm

header "Restarting Minikube (Docker driver)"
minikube delete --profile=minikube &>/dev/null || true
minikube start --driver=docker

header "Helm deploy (NodePort, no ingress)"
helm upgrade --install "$PROJECT_NAME" "$HELM_PATH"

header "Waiting for app to be ready..."
kubectl rollout status deployment/"$PROJECT_NAME" --timeout=120s

header "Access your app"
cat <<EOF
==================================================================
🚀 Done! Your app is deployed!

To open your app in your browser, run in a new terminal:
    minikube service $PROJECT_NAME --url

Press Enter to clean up and remove all local Kubernetes resources...
EOF
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

if [ ${#AUTO_INSTALLED[@]} -gt 0 ]; then
  header "Removing auto-installed dependencies"
  for bin in "${AUTO_INSTALLED[@]}"; do
    sudo rm -f "/usr/local/bin/$bin" 2>/dev/null || true
    echo "Removed: $bin"
    # Optionally try to remove docker via apt if it was installed via the script
    if [[ "$bin" == "docker" ]]; then
      sudo apt-get remove -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    fi
  done
fi

echo "Clean up complete!"
