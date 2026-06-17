output "server_ip" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.devops_lab.ipv4_address
}

output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.devops_lab.id
}
