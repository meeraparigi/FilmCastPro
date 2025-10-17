module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "20.8.4"
    cluster_name = local.cluster_name
    cluster_version = var.kubernetes_version
    cluster_endpoint_public_access = true
    subnet_ids = module.vpc.private_subnets

    enable_irsa = true # required when installing add-ons like Cluster Autoscaler, AWS Load Balancer Controller & EBS/EFS CSI drivers
 
    tags = {
        Environment = var.environment
    }
 
    vpc_id = module.vpc.vpc_id

    # Let module manage SGs
    create_cluster_security_group = true
    create_node_security_group    = true

    # Add only your VPC CIDR for node SG rules
  node_security_group_additional_rules = {
    worker_ingress = {
      description = "Allow internal traffic within VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [module.vpc.vpc_cidr_block]  # <-- only your VPC
      type        = "ingress"
    }

    /*worker_egress = {
      description = "Allow outbound traffic to anywhere"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      type        = "egress"
    }*/
  }
    # Added: IAM policies for worker node functionality
    eks_managed_node_group_defaults = {
        ami_type       = "AL2_x86_64"
        instance_types = var.nodegroup_instancetype
        iam_role_additional_policies = {
          AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        }
    }
    eks_managed_node_groups = {
        node_group = {
            min_size = 2
            max_size = 6
            desired_size = 2
        }
    }
}