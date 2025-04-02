# Terraform Infrastructure Configuration README

## Overview

This Terraform configuration defines the setup of a basic AWS infrastructure. It includes:

- A Virtual Private Cloud (VPC) with a public subnet
- An Internet Gateway to allow internet access
- A Network Address Translation (NAT) Gateway
- Security Groups with specific ingress and egress rules
- Key Pair management for SSH access
- An EC2 instance running Ubuntu

The configuration provisions resources to create a secure and scalable environment for hosting instances and services. 

## Prerequisites

- Terraform v0.12 or higher
- AWS Account with necessary permissions to create VPC, EC2, and other resources
- AWS CLI configured with appropriate credentials

## Components

### 1. **VPC Creation**

A VPC with CIDR block `10.0.0.0/16` is created along with DNS support.

```hcl
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```

### 2. **Subnets**

A public subnet is created within the VPC in the first available availability zone.

```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  availability_zone       = data.aws_availability_zones.available.names.0
  cidr_block              = cidrsubnet(aws_vpc.example.cidr_block, 8, 0) // "10.0.0.0/24"
  map_public_ip_on_launch = true
}
```

### 3. **Internet Gateway**

An Internet Gateway is created and associated with the VPC for internet connectivity.

```hcl
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.example.id
}
```

### 4. **Route Tables**

A route table is created for the public subnet to route traffic to the internet through the Internet Gateway.

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
}
```

### 5. **Security Groups**

- A security group is created for the VPC.
- Ingress rules are defined for SSH (port 22), HTTP (port 80), Nomad API (port 4646), and OpenStack Object Store (port 8080).

```hcl
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.example.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
```

### 6. **SSH Key Pair**

A new RSA private key is generated for SSH access, and a new AWS key pair is created using the public key.

```hcl
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
```

### 7. **EC2 Instance**

- An Ubuntu EC2 instance is launched using the latest AMI for `ubuntu-22.04`.
- The instance is associated with the public subnet, a security group, and the SSH key pair for access.

```hcl
resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.example.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 200
  }

  tags = {
    Name = "ubuntu"
  }
}
```

## Variables

- **instance_type**: The EC2 instance type to be used (e.g., `t2.micro`).

Example for declaring the variable in your `terraform.tfvars`:

```hcl
instance_type = "t2.micro"
```

## Outputs

- **ubuntu_public_ip**: The public IP address of the EC2 instance.

Example output configuration:

```hcl
output "ubuntu_public_ip" {
  value = aws_instance.ubuntu.public_ip
}
```

## Apply the Configuration

1. Initialize the Terraform configuration:

   ```bash
   terraform init
   ```

2. Plan the infrastructure changes:

   ```bash
   terraform plan
   ```

3. Apply the configuration:

   ```bash
   terraform apply
   ```

## Cleanup

To remove all the resources created by this configuration, use:

```bash
terraform destroy
```

## Notes

- Make sure that your AWS credentials are configured properly to avoid any permission-related issues.
- This setup is designed for a simple, public-facing EC2 instance. For production environments, consider adding more robust security and high-availability configurations (e.g., private subnets, ALBs, Auto Scaling, etc.).