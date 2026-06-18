# DevOps Infra on Hetzner Cloud

Infrastructure as Code project that provisions, hardens, deploys, and
serves real applications across multiple cloud servers — built as a
hands-on portfolio to practice and demonstrate production DevOps
workflows, not a tutorial copy.

**Live site:** [sergiomarin.dev](https://sergiomarin.dev)

## What this proves

- Provisioning real cloud infrastructure with Terraform, across
  multiple servers from a single codebase
- Hardening and configuring servers with Ansible, organized into
  reusable roles (common / webserver / k3s), idempotently
- Containerizing and running applications with Docker / Docker Compose
- Running a real Kubernetes cluster (k3s) and deploying workloads to
  it as Deployments and Services
- Automating build and deploy with a real CI/CD pipeline (GitHub Actions)
- Issuing and auto-renewing TLS certificates with Let's Encrypt
- Diagnosing real production issues under pressure — DNS
  misconfiguration, firewall rules, certificate validation failures,
  Ansible overwriting its own SSH keys — see *Real issues found and
  fixed* below

## Architecture

```
Terraform (hcloud)
   |  provisions two servers from one codebase
   v
   +-- devops-lab-01 (Ubuntu 24.04) ---- production-facing
   |        |
   |        v
   |     Ansible: common role + webserver role
   |        - non-root user, SSH key-only, root login disabled
   |        - ufw firewall (22, 80, 443)
   |        - Docker Engine + Compose
   |        - certbot renewal via cron
   |        |
   |        v
   |     Docker Compose stack
   |        - Nginx        -> reverse proxy, TLS termination, static files
   |        - Flask API    -> internal only
   |        - Certbot      -> issues/renews Let's Encrypt certificates
   |        |
   |        v
   |     GitHub Actions (on push to main)
   |        - builds the API image, pushes to GHCR
   |        - deploys to the server over SSH automatically
   |
   +-- k3s-lab-01 (Ubuntu 24.04) ---- kubernetes lab
            |
            v
         Ansible: common role + k3s role
            - same base hardening as above
            - ufw rules for 6443, 8472/udp, 10250
            - k3s installed as a systemd service
            |
            v
         Kubernetes resources (kubectl apply)
            - Deployment: 2 replicas of the same API image
            - Service (ClusterIP): stable internal endpoint
```

## Stack

| Layer | Tools |
|---|---|
| Provisioning | Terraform, Hetzner Cloud |
| Configuration management | Ansible (role-based: common, webserver, k3s) |
| Containers | Docker, Docker Compose |
| Orchestration | Kubernetes (k3s) |
| Reverse proxy / TLS | Nginx, Let's Encrypt (Certbot) |
| CI/CD | GitHub Actions, GitHub Container Registry |
| Application | Python (Flask) |
| DNS / domain | sergiomarin.dev |

## Project structure

```
.
├── terraform/              provisions both servers (Hetzner Cloud)
├── ansible/
│   ├── site.yml            orchestrator playbook
│   ├── inventory.ini        devops_lab + k3s_lab groups
│   └── roles/
│       ├── common/          base hardening, Docker — applies to all servers
│       ├── webserver/        nginx ports, certbot renewal — devops_lab only
│       └── k3s/               k3s install, k8s firewall ports — k3s_lab only
├── app/                     Flask API (Dockerfile + source)
├── nginx/                   reverse proxy + TLS config
├── portfolio/               this site's static frontend
├── k8s/                     Kubernetes manifests (Deployment, Service)
├── .github/workflows/       CI/CD pipeline definition
├── docker-compose.yml       application stack for devops_lab
└── docs/architecture.md     design decisions log
```

## How it works, end to end

**1. Provision both servers**
```
cd terraform && terraform init && terraform plan && terraform apply
```
Creates both servers on Hetzner Cloud and installs the SSH key on
each — no password access exists from the first boot.

**2. Configure each server with its role**
```
cd ansible
ansible-playbook -i inventory.ini site.yml --limit devops_lab
ansible-playbook -i inventory.ini site.yml --limit k3s_lab
```
`common` runs on both; `webserver` only applies to `devops_lab`,
`k3s` only to `k3s_lab`. Fully idempotent — safe to re-run any time.

**3. Deploy the web stack**
```
docker compose up -d
```
Runs the API, Nginx, and Certbot on `devops-lab-01`.

**4. Deploy workloads to Kubernetes**
```
export KUBECONFIG=/path/to/k3s-kubeconfig.yaml
kubectl apply -f k8s/
```
Runs the same API image as a 2-replica Deployment on `k3s-lab-01`,
exposed internally via a ClusterIP Service.

**5. Ship changes**
Push to `main` — GitHub Actions builds the image, publishes it to
GHCR, and deploys the web stack automatically. No manual SSH step
required for ordinary code changes.

## Real issues found and fixed

Building this wasn't just running tutorial commands — these are actual
problems hit and diagnosed during the build, kept here because working
through them is the real skill, not the final clean config:

- **Dual-stack DNS breaking Let's Encrypt validation.** The domain had
  both an A and a leftover AAAA record. Let's Encrypt's HTTP-01
  challenge tried validating over IPv6, which wasn't actually served
  correctly, causing 404s even though IPv4 worked fine. Fixed by
  removing the stray AAAA record.
- **Firewall blocking HTTPS after enabling SSL.** `ufw` only allowed
  ports 22 and 80 from the initial hardening pass. Adding port 443 to
  Nginx without updating the firewall caused silent "connection
  refused" errors. Fixed in code, in Ansible, not just on the server.
- **Ansible's `copy` module overwriting `authorized_keys`.** Using
  `copy` for the SSH key task replaced the entire file on every
  playbook run, silently deleting a second key (added for CI/CD
  deploys) that Ansible didn't know about. Switched to the
  `authorized_key` module, which adds keys without removing others.
- **`docker compose run` silently ignoring commands.** A service
  defined with `entrypoint: "true"` (intended to keep an idle Certbot
  container available) interfered with `run`, swallowing the actual
  command. Fixed by explicitly overriding `--entrypoint` on each run.
- **A monolithic playbook doesn't scale across server roles.** The
  original single playbook applied web-server-specific firewall rules
  to every host, including a future Kubernetes node that didn't need
  them. Refactored into Ansible roles (`common`, `webserver`, `k3s`)
  orchestrated by one playbook, so each server only gets what its role
  actually requires.
- **A server accidentally left in Hetzner's rescue mode.** After a
  reboot, SSH started rejecting all known credentials with a changed
  host key. Investigated methodically rather than assuming a breach:
  checked Hetzner's account activity, confirmed no unauthorized SSH
  logins, and used the Hetzner web console to discover the server had
  booted into its temporary rescue OS instead of the real disk.
  Disabling rescue mode and rebooting restored normal access.

## Status

- [x] Phase 1 — Provisioning & hardening (Terraform + Ansible)
- [x] Phase 2 — Dockerized Flask API behind Nginx reverse proxy
- [x] Phase 3 — CI/CD pipeline (GitHub Actions)
- [x] Phase 4 — Personal portfolio site + HTTPS (Let's Encrypt)
- [x] Phase 5 — Ansible roles refactor + Kubernetes (k3s) cluster
- [ ] Phase 6 — Monitoring & observability (Prometheus + Grafana)
- [ ] Phase 7 — Centralized logging (Loki)

## About

Built by [Sergio Marín](https://sergiomarin.dev) — 13+ years in
infrastructure, middleware, and backend development, now formalizing
that experience into modern DevOps practice.
