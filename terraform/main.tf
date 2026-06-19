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

resource "hcloud_server" "k3s_lab" {
  name        = var.k3s_server_name
  server_type = var.k3s_server_type
  image       = "ubuntu-24.04"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    project     = "devops-infra-hetzner"
    environment = "k3s-lab"
  }
}

resource "hcloud_firewall" "webserver" {
  name = "webserver-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9100"
    source_ips = ["178.105.73.106/32"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8080"
    source_ips = ["178.105.73.106/32"]
  }
}

resource "hcloud_firewall" "k3s" {
  name = "k3s-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "8472"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "10250"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "30300"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3100"
    source_ips = ["46.225.149.114/32"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "31000"
    source_ips = ["46.225.149.114/32"]
  }
}

resource "hcloud_firewall_attachment" "webserver" {
  firewall_id = hcloud_firewall.webserver.id
  server_ids  = [hcloud_server.devops_lab.id]
}

resource "hcloud_firewall_attachment" "k3s" {
  firewall_id = hcloud_firewall.k3s.id
  server_ids  = [hcloud_server.k3s_lab.id]
}
