output "vpc_id" {
  value = module.proxmox.vpc_id
}

output "mgmt_subnet_id" {
  value = module.proxmox.mgmt_subnet_id
}

output "sdn_subnet_id" {
  value = module.proxmox.sdn_subnet_id
}

output "instance_id" {
  value = module.proxmox.instance_id
}

output "proxmox_creds" {
  value = module.proxmox.proxmox_creds
  sensitive = true
}

output "proxmox_private_ips" {
  value = module.proxmox.proxmox_private_ips
}

