data "aws_availability_zones" "available" {}

resource "aws_vpc" "proxmox" {
  cidr_block           = "192.168.0.0/20"
  enable_dns_hostnames = true

  tags = {
    Name = "proxmox"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.proxmox.id

  tags = {
    Name = "proxmox"
  }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"

  tags = {
    Name = "proxmox-ngw"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "proxmox"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.proxmox.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "proxmox-mgmt-default"
  }
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.mgmt.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.proxmox.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id   = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.proxmox.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "proxmox-public"
  }
}

resource "aws_subnet" "mgmt" {
  vpc_id            = aws_vpc.proxmox.id
  cidr_block        = "192.168.4.0/22"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "proxmox-mgmt"
  }
}

resource "aws_subnet" "sdn" {
  vpc_id            = aws_vpc.proxmox.id
  cidr_block        = "192.168.8.0/22"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "proxmox-sdn"
  }
}

# IAM and SSM for Bastions
resource "aws_iam_role" "ssm" {
  name = "${var.name_prefix}-proxmox-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name_prefix}-ssm-instance-profile"
  role = aws_iam_role.ssm.name
}

data "aws_ami" "proxmox" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["proxmox-ami-*"]
  }
}

resource "aws_security_group" "proxmox" {
  name        = "${var.name_prefix}-proxmox"
  description = "Allow SSH and Proxmox Web UI"
  vpc_id      = aws_vpc.proxmox.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.mgmt.cidr_block]
  }

  ingress {
    from_port   = 8006
    to_port     = 8006
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.mgmt.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "proxmox-mgmt"
  }
}

resource "random_string" "root_password" {
  length  = 16
  special = false
}

resource "tls_private_key" "root_ssh" {
  algorithm = "RSA"
  rsa_bits  = 3072
}

resource "aws_network_interface" "proxmox_mgmt" {
  count           = var.proxmox_node_count
  subnet_id       = aws_subnet.mgmt.id
  security_groups = [aws_security_group.proxmox.id]

  tags = {
    Name = "${var.name_prefix}-proxmox-mgmt-${count.index}"
  }
}

resource "aws_network_interface" "proxmox_sdn" {
  count           = var.proxmox_node_count
  subnet_id       = aws_subnet.sdn.id
  security_groups = [aws_security_group.proxmox.id]

  tags = {
    Name = "${var.name_prefix}-proxmox-sdn-${count.index}"
  }
}

resource "aws_network_interface_attachment" "proxmox_sdn" {
  count                = var.detach_sdn_interface ? 0 : var.proxmox_node_count
  device_index         = 1
  instance_id          = aws_instance.proxmox[count.index].id
  network_interface_id = aws_network_interface.proxmox_sdn[count.index].id
}

resource "aws_ebs_volume" "proxmox_data" {
  count             = var.proxmox_node_count
  availability_zone = aws_subnet.mgmt.availability_zone
  size              = var.proxmox_data_volume_size
  type              = "gp3"
  tags = {
    Name = "${var.name_prefix}-proxmox-data-${count.index}"
  }
}

resource "aws_instance" "proxmox" {
  count                = var.proxmox_node_count
  ami                  = data.aws_ami.proxmox.id
  instance_type        = var.proxmox_instance_type
  iam_instance_profile = aws_iam_instance_profile.ssm.name

  user_data = templatefile("${path.module}/files/cloud-init.yaml.tftpl", {
    root_password        = random_string.root_password.result
    root_ssh_public_key  = tls_private_key.root_ssh.public_key_openssh
    root_ssh_private_key = tls_private_key.root_ssh.private_key_openssh
    proxmox_private_ips  = jsonencode(aws_network_interface.proxmox_mgmt[*].private_ip)
  })

  metadata_options {
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.proxmox_mgmt[count.index].id
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.name_prefix}-proxmox-${count.index}"
  }
}

resource "aws_volume_attachment" "proxmox_data" {
  count                          = var.detach_data_volume ? 0 : var.proxmox_node_count
  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.proxmox_data[count.index].id
  instance_id                    = aws_instance.proxmox[count.index].id
  stop_instance_before_detaching = true
}
