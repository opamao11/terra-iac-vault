variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for Kubernetes node"
  default     = "t2.small"
}

variable "ami_id" {
  description = "Amazon Machine Image ID for the EC2 instance"
  default     = "ami-0866a3c8686eaeeba" # Update based on region
}

variable "key_name" {
  description = "Name of the EC2 Key Pair"
  default     = "terra-iac"
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be created"
  default     = "vpc-0f2a46d1e856a1877"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
}

variable "security_group_id" {
  description = "Security group ID for EC2 instance access"
  default     = "sg-0b1d3c9881b8b2861"
}
