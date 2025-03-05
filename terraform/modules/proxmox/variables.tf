variable "name_prefix" {}
variable "aws_region" {}
variable "proxmox_node_count" { type = number }
variable "proxmox_instance_type" {}
variable "proxmox_data_volume_size" {}
variable "detach_sdn_interface" {
  type    = bool
  default = false
}
variable "detach_data_volume" {
  type    = bool
  default = false
}
