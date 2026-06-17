# DevOps Infra on Hetzner Cloud

Infrastructure as Code project that provisions and hardens a cloud server
end-to-end: Terraform creates the infrastructure, Ansible configures and
secures it. Built as a hands-on portfolio project to practice real-world
DevOps workflows.

## Architecture

```
Terraform (hcloud)  --provisions-->  Hetzner Server (Ubuntu 24.04)
                                            |
                                            v
                                     Ansible configures:
                                       - non-root user
                                       - SSH hardening
                                       - ufw firewall
```

## Stack

- **Terraform** — infrastructure provisioning (Hetzner Cloud provider)
- **Ansible** — server configuration and hardening
- **Hetzner Cloud** — CX23, Ubuntu 24.04, Falkenstein (fsn1)

## What it does

**Terraform**
- Uploads a local SSH public key to Hetzner Cloud
- Provisions a server with that key pre-installed (no password access from the start)
- Outputs the server's public IP and ID

**Ansible**
- Updates and upgrades system packages
- Creates a non-root `devops` user with passwordless sudo
- Installs the local SSH public key for that user
- Disables root login over SSH
- Disables SSH password authentication (key-only access)
- Installs and enables ufw, allowing only SSH traffic

## Project structure

```
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── roles/
└── docs/
    └── architecture.md
```

## Usage

### 1. Provision the server

```
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real Hetzner API token
terraform init
terraform plan
terraform apply
```

### 2. Configure and harden it

Update ansible/inventory.ini with the IP from the Terraform output, then:

```
cd ansible
ansible-galaxy collection install community.general
ansible -i inventory.ini devops_lab -m ping
ansible-playbook -i inventory.ini playbook.yml
```

### 3. Verify

```
ssh devops@<server_ip>     # should work, key-based
ssh root@<server_ip>       # should be rejected
```

## Status

- [x] Phase 1 — Provisioning & hardening (Terraform + Ansible)
- [ ] Phase 2 — Dockerized reverse proxy with automated SSL
- [ ] Phase 3 — CI/CD pipeline (GitHub Actions)
- [ ] Phase 4 — Monitoring & observability (Prometheus + Grafana)
- [ ] Phase 5 — Kubernetes (k3s)
- [ ] Phase 6 — Centralized logging (Loki)
