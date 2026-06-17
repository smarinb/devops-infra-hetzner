# DevOps Infra on Hetzner Cloud

Infrastructure as Code project that provisions, hardens, and deploys
containerized applications on a cloud server end-to-end: Terraform
creates the infrastructure, Ansible configures and secures it, and
Docker Compose runs the application stack. Built as a hands-on
portfolio project to practice real-world DevOps workflows.

## Live demo

- `http://46.225.149.114/` — Flask API root endpoint
- `http://46.225.149.114/health` — health check endpoint

## Architecture

Terraform (hcloud)  --provisions-->  Hetzner Server (Ubuntu 24.04)
                                            |
                                            v
                                     Ansible configures:
                                       - non-root user
                                       - SSH hardening
                                       - ufw firewall
                                       - Docker installation
                                            |
                                            v
                                     Docker Compose runs:
                                       - Nginx (reverse proxy, port 80)
                                       - Flask API (internal only)

## Stack

- **Terraform** — infrastructure provisioning (Hetzner Cloud provider)
- **Ansible** — server configuration, hardening, and Docker installation
- **Docker / Docker Compose** — containerized application stack
- **Flask** — minimal Python API
- **Nginx** — reverse proxy
- **Hetzner Cloud** — CX23, Ubuntu 24.04, Falkenstein (fsn1)

## What it does

**Terraform**
- Uploads a local SSH public key to Hetzner Cloud
- Provisions a server with that key pre-installed (no password access from the start)
- Outputs the server's public IP and ID

**Ansible**
- Updates and upgrades system packages
- Creates a non-root devops user with passwordless sudo
- Installs the local SSH public key for that user
- Disables root login over SSH
- Disables SSH password authentication (key-only access)
- Installs and enables ufw, allowing only SSH and HTTP traffic
- Installs Docker Engine and the Compose plugin via the official Docker apt repository
- Adds the devops user to the docker group (no sudo needed for docker commands)

**Docker Compose stack**
- A minimal Flask API (/ and /health endpoints), containerized with a pinned-dependency Dockerfile
- Nginx as a reverse proxy in front of it, the only service exposed to the host
- The API container has no published port, it's only reachable through Nginx, mirroring a real production setup

## Project structure

.
- terraform/
  - main.tf
  - variables.tf
  - outputs.tf
  - terraform.tfvars.example
- ansible/
  - inventory.ini
  - playbook.yml
  - roles/
- app/
  - app.py
  - requirements.txt
  - Dockerfile
- nginx/
  - nginx.conf
- docker-compose.yml
- docs/
  - architecture.md

## Usage

### 1. Provision the server

cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

### 2. Configure, harden, and install Docker

cd ansible
ansible-galaxy collection install community.general
ansible -i inventory.ini devops_lab -m ping
ansible-playbook -i inventory.ini playbook.yml

### 3. Verify hardening

ssh devops@server_ip
ssh root@server_ip

### 4. Deploy the application stack

git clone https://github.com/smarinb/devops-infra-hetzner.git
cd devops-infra-hetzner
docker compose build
docker compose up -d

### 5. Verify the stack

curl http://server_ip/
curl http://server_ip/health

## Status

- [x] Phase 1 — Provisioning & hardening (Terraform + Ansible)
- [x] Phase 2 — Dockerized Flask API behind Nginx reverse proxy
- [x] Phase 3 — CI/CD pipeline (GitHub Actions)
- [ ] Phase 4 — Monitoring & observability (Prometheus + Grafana)
- [ ] Phase 5 — Kubernetes (k3s)
- [ ] Phase 6 — Centralized logging (Loki)
