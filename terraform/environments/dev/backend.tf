terraform {
  backend "s3" {
    region         = "us-east-1"
    key            = "dev/terraform.tfstate"
    bucket         = "foundry-proxmox-terraform-state"
    dynamodb_table = "foundry-proxmox-terraform-locks"
  }
}
