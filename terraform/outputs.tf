output "server_ip" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.devops_lab.ipv4_address
}

output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.devops_lab.id
}

output "k3s_server_ip" {
  description = "Public IPv4 address of the k3s lab server"
  value       = hcloud_server.k3s_lab.ipv4_address
}

output "k3s_server_id" {
  description = "Hetzner server ID of the k3s lab server"
  value       = hcloud_server.k3s_lab.id
}
