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

output "aws_ec2_public_ip" {
  description = "Public IP of the AWS EC2 instance"
  value       = aws_eip.devops_lab.public_ip
}

output "aws_ec2_instance_id" {
  description = "AWS EC2 instance ID"
  value       = aws_instance.devops_lab.id
}
