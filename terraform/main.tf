terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "devops-lab-key"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "devops_lab" {
  name        = var.server_name
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    project     = "devops-infra-hetzner"
    environment = "lab"
  }
}
