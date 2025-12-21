#!/usr/bin/env bash
set -e

PROJECT_NAME="hello-app"
HELM_PATH="helm/hello-world"
IMAGE_REPO="guy66bp/hello-world-app"
IMAGE_TAG="latest"
APP_SECRET="local-secret"

### Utility: Install a dependency if missing ###
install_if_missing() {
    local bin="$1"
    local brew_pkg="$2"
    local apt_pkg="$3"
    local install_url="$4"

    if ! command -v $bin &>/dev/null; then
        echo "$bin not found. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &>/dev/null; then
                brew install "$brew_pkg"
            else
                echo "Please install Homebrew to proceed."
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &>/dev/null; then
                sudo apt-get update
                sudo apt-get install -y "$apt_pkg"
            else
                echo "No apt found. Trying direct download."
                curl -Lo "$bin-tmp" "$install_url"
                chmod +x "$bin-tmp"
                sudo mv "$bin-tmp" /usr/local/bin/"$bin"
            fi
        else
            echo "Unsupported OS. Please install $bin manually."
            exit 1
        fi
    else
        echo "$bin found."
    fi
}

print_header() {
  echo
  echo "===[ $1 ]==="
}

print_header "Checking and installing dependencies (docker, minikube, helm, kubectl)"
install_if_missing docker docker.io docker.io https://get.docker.com/
install_if_missing minikube minikube minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install_if_missing kubectl kubectl kubectl "$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | \
  xargs -I {} echo https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubectl)"
install_if_missing helm helm helm https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

print_header "Starting (or restarting) minikube with Docker driver"
if minikube status &>/dev/null; then
    minikube stop
    minikube delete
fi
minikube start --driver=docker

print_header "Deploying with Helm (NodePort service, no ingress)"
helm upgrade --install "$PROJECT_NAME" "$HELM_PATH"

print_header "Waiting for app pod to be ready..."
kubectl rollout status deployment/"$PROJECT_NAME" --timeout=120s

print_header "Determining Minikube Node IP and NodePort for browser access..."
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc "$PROJECT_NAME" -o=jsonpath='{.spec.ports[0].nodePort}')
APP_URL="http://${MINIKUBE_IP}:${NODE_PORT}"
echo
echo "=================================================================="
echo "🚀 Done! Your app should be accessible at: $APP_URL"
echo "(Minikube Docker driver: use this address, not 127.0.0.1)"
echo "Open your browser and check!"
echo
echo "Press Enter to clean up and remove all local Kubernetes resources..."
read

print_header "Cleaning up: Uninstalling Helm release and deleting Minikube cluster"
helm uninstall "$PROJECT_NAME" 2>/dev/null || true
minikube stop
minikube delete

echo "Clean up complete!"
