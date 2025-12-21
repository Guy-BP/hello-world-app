#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
HELM_PATH="helm/hello-world"
IMAGE_REPO="guy66bp/hello-world-app"
IMAGE_TAG="latest"

AUTO_INSTALLED=()

header() { echo -e "\n===[ $1 ]===\n"; }

auto_install() {
  local bin="$1" url="$2"
  if ! command -v $bin &>/dev/null; then
    TMP_BIN="$(mktemp)"
    echo "$bin not found. Auto-installing temporarily..."
    curl -fsSL "$url" -o "$TMP_BIN"
    chmod +x "$TMP_BIN"
    sudo mv "$TMP_BIN" "/usr/local/bin/$bin"
    AUTO_INSTALLED+=("$bin")
  fi
}

header "Checking and auto-installing dependencies if needed (docker, minikube, helm, kubectl)"

auto_install docker https://get.docker.com/
auto_install minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
auto_install kubectl "$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | \
  xargs -I {} echo https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubectl)"
auto_install helm https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

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
    minikube service $PROJECT_NAME


Press Enter to clean up and remove all local Kubernetes resources...
EOF
read

header "Cleanup"
helm uninstall "$PROJECT_NAME" &>/dev/null || true
minikube delete

if ((${#AUTO_INSTALLED[@]})); then
  header "Removing auto-installed binaries"
  for bin in "${AUTO_INSTALLED[@]}"; do
    sudo rm -f "/usr/local/bin/$bin" && echo "Removed: $bin"
  done
fi

echo "Clean up complete!"
