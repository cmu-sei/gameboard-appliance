output "vpc_id" {
  value = aws_vpc.proxmox.id
}

output "mgmt_subnet_id" {
  value = aws_subnet.mgmt.id
}

output "sdn_subnet_id" {
  value = aws_subnet.sdn.id
}

output "instance_id" {
  value = aws_instance.proxmox[*].id
}

output "proxmox_private_ips" {
  value = aws_instance.proxmox[*].private_ip
}

output "proxmox_creds" {
  value = {
    username = "root"
    password = random_string.root_password.result
  }
  sensitive = true
}
