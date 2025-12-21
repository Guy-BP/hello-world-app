# Hello Flask App – CI/CD and Kubernetes Quick Start

## 🚀 How to Run This Project

### Local Deployment

```bash
git clone https://github.com/Guy-BP/hello-world-app.git
cd hello-world-app
chmod +x deploy-local.sh
./deploy-local.sh
```
- The script will automatically install any missing dependencies (`docker`, `kubectl`, `helm`, `minikube`).
- Your app is built, deployed to Minikube via Helm, and local url will be shown to you in the terminal using `minikube service hello-app`.
- When done, cleanup is automatic, including removal of CLI tools that were not pre-installed on the machine .

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
  - Builds and pushes the Docker image to Docker Hub
  - Handles Dockerhub credentials using GitHub Secrets.

### 2. Local Deploy Script (`deploy-local.sh`)
- **Purpose:** Instantly sets up a local Kubernetes demo.
- **What it does:**  
  - Installs missing dependencies (removed after cleanup).
  - Starts or resets a Minikube cluster (Docker driver).
  - Deploys your Flask app with Helm as a NodePort service.
  - Tells you how to open the app in your browser.
  - Cleans up all deployed resources and any installed tools afterward.

### 3. Helm Chart (`helm/hello-world/`)
- **Purpose:** Manages configuration and deployment of your app to Kubernetes.
- **Key files:**  
    - `Chart.yaml` — Helm chart definition.
    - `values.yaml` — Default settings: image, ports, etc.
    - `templates/deployment.yaml` — Defines the app’s Deployment.
    - `templates/service.yaml` — Exposes the app via NodePort.
- **What it does:**  
  - Parameterizes the Docker image, port, and ingress.
  - Allows simple local or cloud deployment using a single set of flexible templates.

---

## 💡 Summary

- **CI/CD:** Pushing to `main` builds and publishes Docker image (and can deploy to production).
- **Local Demo:**  
    - `deploy-local.sh` = portable, zero-config, full-cycle app delivery to your laptop.
- **Helm Chart:** Flexible, customizable Kubernetes deployment—ready for local or remote clusters.

---
