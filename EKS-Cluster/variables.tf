variable "kubernetes_version" {
    default = 1.32
    description = "Kubernetes version"
}
 
variable "vpc_name" {
    default = "filmcastpro-vpc"
    description = "Name of the VPC"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description = "Default CIDR range for the VPC"
}
 
variable "aws_region" {
    default = "us-east-1"
    description = "AWS region"
}

variable "nodegroup_instancetype" {
  description = "Instance Type of EKS Node Group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "environment" {
  description = "Provisioning Infrastructure in specified Environment"
  default     = "dev"
}