# Hello Flask App – CI/CD and Kubernetes Quick Start

## 🚀 How to Run This Project

### Local Deployment (with Minikube & NodePort)

```bash
git clone https://github.com/Guy-BP/hello-world-app.git
cd hello-world-app
chmod +x deploy-local.sh
./deploy-local.sh
```
- The script will **check for required dependencies** (`docker`, `kubectl`, `helm`, `minikube`) and prompt if missing.
- Your app is built, deployed to Minikube via Helm, and exposed via a **Kubernetes NodePort Service**.
- To access your app, **open a new terminal** and run:
  ```bash
  minikube service hello-app --url
  ```
  - Copy and open the outputted URL in your browser to see the app!
- When finished, return to the script and **press Enter** for automatic clean-up of the app and Minikube resources.

---

### GitHub Actions Workflow (CI/CD)

- On manual dispatch, GitHub Actions automatically:
    1. **Builds** your Docker image from `app/`
    2. **Pushes** the image to Docker Hub (using secrets configured in repo settings)

---

## 🧩 Components Explained

### 1. GitHub Actions Workflow
- File: `.github/workflows/ci-cd.yaml`
- **Purpose:** Automates CI/CD for your app.
- **What it does:**  
  - Builds and pushes the Docker image to Docker Hub.
  - Handles Docker Hub credentials using GitHub Secrets.

### 2. Local Deploy Script (`deploy-local.sh`)
- **Purpose:** One-command portable local Kubernetes demo (Minikube).
- **What it does:**  
  - Checks for required dependencies.
  - Starts or resets a Minikube cluster (using the Docker driver).
  - Installs the app’s Helm chart, which creates a Deployment and NodePort Service.
  - Prints instructions to get a browser URL using `minikube service hello-app --url`.
  - Cleans up all deployed resources when you press Enter.

### 3. Helm Chart (`helm/hello-world/`)
- **Purpose:** Kubernetes application/lifecycle configuration and deployment.
- **Key files:**  
    - `Chart.yaml` — Helm chart definition.
    - `values.yaml` — Default settings: image, replica count, service type (NodePort), etc.
    - `templates/deployment.yaml` — Defines the app’s Deployment.
    - `templates/service.yaml` — Exposes the app via NodePort Service.
- **What it does:**  
  - Parameterizes the Docker image, port, replica count, and service type.

---

## 💡 Summary

- **CI/CD:** Manually run workflow builds and pushes Docker image to registry.
- **Local Demo:**  
    - `deploy-local.sh` provides zero-config, full-cycle Minikube app demo via NodePort service.
- **Helm Chart:** customizable Kubernetes deployment—ready for local or cloud clusters.

---
