terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8081"
    source_ips = ["0.0.0.0/0", "::/0"]
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

# ─── AWS INFRASTRUCTURE ───────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name    = "devops-lab-vpc"
    project = "devops-infra-hetzner"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "devops-lab-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "devops-lab-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "devops-lab-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "devops_lab" {
  name        = "devops-lab-sg"
  description = "Security group for devops lab EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "devops-lab-sg"
    project = "devops-infra-hetzner"
  }
}

resource "aws_key_pair" "devops_lab" {
  key_name   = "devops-lab-key-aws"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_instance" "devops_lab" {
  ami                    = "ami-05bfa4a7765f38076"
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.devops_lab.id]
  key_name               = aws_key_pair.devops_lab.key_name

  tags = {
    Name    = "devops-lab-ec2"
    project = "devops-infra-hetzner"
  }
}

resource "aws_eip" "devops_lab" {
  instance = aws_instance.devops_lab.id
  domain   = "vpc"
  tags = {
    Name = "devops-lab-eip"
  }
}
