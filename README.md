# DevOps Infra on Hetzner Cloud

Infrastructure as Code project that provisions, hardens, deploys, and
serves real applications on a cloud server end to end — built as a
hands-on portfolio to practice and demonstrate production DevOps
workflows, not a tutorial copy.

**Live site:** [sergiomarin.dev](https://sergiomarin.dev)

## What this proves

- Provisioning real cloud infrastructure with Terraform
- Hardening and configuring a server with Ansible, idempotently
- Containerizing and running applications with Docker / Docker Compose
- Automating build and deploy with a real CI/CD pipeline (GitHub Actions)
- Issuing and auto-renewing TLS certificates with Let's Encrypt
- Diagnosing real production issues: DNS misconfiguration, firewall
  rules, certificate validation failures — see *Real issues found and
  fixed* below

## Architecture

```
Terraform (hcloud)
   |  provisions
   v
Hetzner Cloud server (Ubuntu 24.04)
   |
   v
Ansible
   - creates non-root user, SSH key-only access, root login disabled
   - configures ufw firewall (22, 80, 443)
   - installs Docker Engine + Compose
   - schedules certbot renewal via cron
   |
   v
Docker Compose stack
   - Nginx        -> reverse proxy, TLS termination, static files
   - Flask API    -> internal only, not exposed to the host
   - Certbot      -> issues and renews Let's Encrypt certificates
   |
   v
GitHub Actions (on push to main)
   - builds the API image
   - pushes it to GitHub Container Registry
   - deploys to the server over SSH automatically
```

## Stack

| Layer | Tools |
|---|---|
| Provisioning | Terraform, Hetzner Cloud |
| Configuration management | Ansible |
| Containers | Docker, Docker Compose |
| Reverse proxy / TLS | Nginx, Let's Encrypt (Certbot) |
| CI/CD | GitHub Actions, GitHub Container Registry |
| Application | Python (Flask) |
| DNS / domain | sergiomarin.dev |

## Project structure

```
.
├── terraform/              server provisioning (Hetzner Cloud)
├── ansible/                hardening, Docker install, firewall, cron
├── app/                    Flask API (Dockerfile + source)
├── nginx/                  reverse proxy + TLS config
├── portfolio/              this site's static frontend
├── .github/workflows/      CI/CD pipeline definition
├── docker-compose.yml      full application stack
└── docs/architecture.md    design decisions log
```

## How it works, end to end

**1. Provision**
```
cd terraform && terraform init && terraform plan && terraform apply
```
Creates the server on Hetzner Cloud and installs the SSH key — no
password access exists from the first boot.

**2. Configure**
```
cd ansible && ansible-playbook -i inventory.ini playbook.yml
```
Hardens SSH, configures the firewall, installs Docker, and schedules
certificate renewal. Fully idempotent — safe to re-run any time.

**3. Deploy the stack**
```
docker compose up -d
```
Runs the API, Nginx, and prepares Certbot. The very first certificate
is issued once manually; renewal afterward is automatic via cron.

**4. Ship changes**
Push to `main` — GitHub Actions builds the image, publishes it to
GHCR, and deploys it to the server automatically. No manual SSH step
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

## Status

- [x] Phase 1 — Provisioning & hardening (Terraform + Ansible)
- [x] Phase 2 — Dockerized Flask API behind Nginx reverse proxy
- [x] Phase 3 — CI/CD pipeline (GitHub Actions)
- [x] Phase 4 — Personal portfolio site + HTTPS (Let's Encrypt)
- [ ] Phase 5 — Monitoring & observability (Prometheus + Grafana)
- [ ] Phase 6 — Kubernetes (k3s)
- [ ] Phase 7 — Centralized logging (Loki)

## About

Built by [Sergio Marín](https://sergiomarin.dev) — 13+ years in
infrastructure, middleware, and backend development, now formalizing
that experience into modern DevOps practice.
