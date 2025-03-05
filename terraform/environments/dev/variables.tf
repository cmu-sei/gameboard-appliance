variable "aws_region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "proxmox_node_count" {
  description = "Number of Proxmox nodes to deploy"
  type        = number
  default     = 3
}

variable "proxmox_instance_type" {
  description = "Instance type for Proxmox nodes"
  default     = "t3.small"
}

variable "proxmox_data_volume_size" {
  description = "Size of data volume to create for each Proxmox node (in GB)"
  default     = 30
}

variable "detach_data_volume" {
  description = "Detach data volume from Proxmox nodes (useful for quickly recreating instances)"
  type        = bool
  default     = false
}

variable "detach_sdn_interface" {
  description = "Detach SDN interface from Proxmox nodes (useful for quickly recreating instances)"
  type        = bool
  default     = false
}
