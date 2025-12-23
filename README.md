# Hello Flask App – CI/CD and Kubernetes Quick Start

## 🚀 How to Run This Project

### Local Deployment (with Minikube & Ingress)

```bash
git clone https://github.com/Guy-BP/hello-world-app.git
cd hello-world-app
chmod +x deploy-local.sh
./deploy-local.sh
```
- The script will **automatically install any missing dependencies** (`docker`, `kubectl`, `helm`, `minikube`).
- Your app is built, deployed to Minikube via Helm and exposed via **Kubernetes Ingress**.
- You will see a local URL in the terminal:  
  - **Open http://hello.local** in your browser to access the app!
  - The script adds/removes the necessary `/etc/hosts` entry and handles all the setup/teardown.
- When done, cleanup is automatic, including removal of CLI tools installed by the script.

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
  - Checks/installs missing dependencies (removed in cleanup).
  - Starts or resets a Minikube cluster (using the Docker driver).
  - Enables the Minikube NGINX Ingress controller.
  - Installs the app’s Helm chart, which creates a Deployment, Service, and Ingress.
  - Adds a `hello.local` entry to `/etc/hosts` mapped to your Minikube IP for browser access.
  - Prints the Ingress URL (`http://hello.local`) for you to use.
  - Cleans up all deployed resources, `/etc/hosts`, and any auto-installed tools on exit.

### 3. Helm Chart (`helm/hello-world/`)
- **Purpose:** Kubernetes application/lifecycle configuration and deployment.
- **Key files:**  
    - `Chart.yaml` — Helm chart definition.
    - `values.yaml` — Default settings: image, replica count, service type, ingress, etc.
    - `templates/deployment.yaml` — Defines the app’s Deployment.
    - `templates/service.yaml` — Exposes the app.
    - `templates/ingress.yaml` — Exposes the app via Ingress at `hello.local`.
- **What it does:**  
  - Parameterizes the Docker image, port, replica count, and ingress host.

---

## 💡 Summary

- **CI/CD:** Manually run workflow builds and pushes Docker image to registry.
- **Local Demo:**  
    - `deploy-local.sh` provides zero-config, full-cycle Minikube + Ingress app demo.
- **Helm Chart:** customizable Kubernetes deployment—ready for local or cloud clusters.

---
