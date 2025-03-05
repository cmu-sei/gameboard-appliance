module "proxmox" {
  source = "../../modules/proxmox"

  name_prefix              = terraform.workspace
  aws_region               = var.aws_region
  proxmox_instance_type    = var.proxmox_instance_type
  proxmox_node_count       = var.proxmox_node_count
  proxmox_data_volume_size = var.proxmox_data_volume_size
  detach_data_volume       = var.detach_data_volume
  detach_sdn_interface     = var.detach_sdn_interface
}
