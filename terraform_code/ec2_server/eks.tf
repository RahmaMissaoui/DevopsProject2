# # Fetch LabRole ARN (failsafe: replace with hardcoded if denied)
# data "aws_iam_role" "lab_role" {
#   name = "LabRole"
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 18.0"  # Downgrade to avoid aws_iam_session_context

#   cluster_name    = "${var.server_name}-eks"
#   cluster_version = "1.30"  

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   # Use static LabRole (bypasses role creation/introspection)
#   create_iam_role     = false
#   iam_role_arn        = data.aws_iam_role.lab_role.arn  # Or hardcoded: "arn:aws:iam::637423542227:role/LabRole"

#   # Basic logging (if permitted; skip if errors)
#   cluster_enabled_log_types = ["api", "audit"]

#   # Disable IRSA to avoid extra IAM roles/policies
#   enable_irsa = false

#   # Node group: Use lab instance profile, small scale for budget
#   eks_managed_node_groups = {
#     default = {
#       instance_types = ["t3.medium"]

#       desired_size = 1
#       min_size     = 1
#       max_size     = 2

#       # Attach lab profile (no new role creation)
#       iam_instance_profile_name = "LabInstanceProfile"

#       # Use static node role if needed (optional; falls back to profile)
#       # iam_role_arn = data.aws_iam_role.lab_role.arn

#       # Tags for identification/cleanup
#       tags = {
#         Name = "${var.server_name}-eks-nodes"
#       }
#     }
#   }
# }



# No data source needed—hardcode from CloudShell output
# (If you prefer dynamic: Uncomment below after testing `aws iam get-role` succeeds consistently)

# data "aws_iam_role" "lab_role" {
#   name = "LabRole"
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.31"  # Stable v18; avoids IAM introspection issues

  cluster_name    = "${var.server_name}-eks"
  cluster_version = "1.30"  # Current standard (1.29 EOL since mid-2025)

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster: Use lab's existing LabRole
  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::637423542227:role/LabRole"

  # Basic logs (CloudWatch if permitted)
  cluster_enabled_log_types = ["api", "audit"]

  # Disable extras to minimize IAM/VPC calls
  enable_irsa     = false
  create_kms_key  = false

  # Node group: Reuse LabRole ARN + profile; small scale for lab budget/limits
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]  # 2 vCPUs; fits 32 vCPU lab cap

      desired_size = 1  # Start minimal (~$0.05/hr)
      min_size     = 1
      max_size     = 2

      # Key fixes: No new role; use existing for nodes + profile for instances
      create_iam_role           = false
      iam_role_arn              = "arn:aws:iam::637423542227:role/LabRole"  # Required: Provides EKS/ECR perms
      iam_instance_profile_name = "LabInstanceProfile"  # Optional: Attaches to launch template

      # Ensure private subnets for nodes
      subnet_ids = module.vpc.private_subnets

      # Tags for console identification/cleanup
      tags = {
        Name = "${var.server_name}-eks-nodes"
      }
    }
  }

  # Cluster tags
  tags = {
    Name = "${var.server_name}-eks-cluster"
  }
}