module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.31"

  cluster_name    = "${var.server_name}-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Use LabRole for cluster (it has AmazonEKSClusterPolicy attached)
  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::637423542227:role/LabRole"

  # Basic logs
  cluster_enabled_log_types = ["api", "audit"]

  # Disable extras
  enable_irsa     = false
  create_kms_key  = false

  # Node group: Also use LabRole (it has AmazonEKSWorkerNodePolicy attached)
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]

      desired_size = 1
      min_size     = 1
      max_size     = 2

      # Use LabRole for nodes too
      create_iam_role           = false
      iam_role_arn              = "arn:aws:iam::637423542227:role/LabRole"
      iam_instance_profile_name = "LabInstanceProfile"

      subnet_ids = module.vpc.private_subnets

      tags = {
        Name = "${var.server_name}-eks-nodes"
      }
    }
  }

  # AWS Auth mapping - Map LabRole to cluster-admin
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::637423542227:role/LabRole"
      username = "labrole-user"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Name = "${var.server_name}-eks-cluster"
  }
}