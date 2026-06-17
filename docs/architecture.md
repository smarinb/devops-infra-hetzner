# Architecture & Design Decisions

## Why Hetzner Cloud

Affordable (CX23 ~5 EUR/month), reliable network performance, and has an
official Terraform provider — a realistic equivalent of working against
AWS/GCP/Azure without the cost overhead of a learning sandbox.

## Why CX23 instead of CX22

Hetzner's available server types differ per datacenter and account. CX23
was confirmed via the Hetzner API (/v1/server_types) as the available
type in fsn1 for this account, replacing the originally planned CX22.

## Why Falkenstein (fsn1)

No latency requirement for a lab/portfolio project; fsn1 is Hetzner's
original and most stable datacenter, with the widest server type
availability.

## Hardening order (why it matters)

The Ansible playbook creates the devops user and installs its SSH key
before disabling root login and password authentication. Reversing this
order would lock out all access to the server, since no valid login
method would remain.

## Secrets management

- terraform.tfvars (real API token) is gitignored; .tfvars.example is
  committed as a template.
- terraform.tfstate is gitignored — it can contain sensitive data and
  represents the single source of truth for what Terraform manages.
- In a team/production setting, state would live in a remote backend
  (e.g. Terraform Cloud, S3) instead of locally.

## Known simplifications (for portfolio purposes)

- ansible/inventory.ini has the server IP hardcoded rather than pulled
  dynamically from Terraform output. In a more mature setup this would be
  automated (e.g. via a script that generates the inventory from
  terraform output).
