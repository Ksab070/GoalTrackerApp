locals {
  region = "us-east-1"

  aws_tags = {
    "Terraform"   = "True"
    "Purpose"     = "EKS-infra"
    "Environment" = "Prod"
  }

  subnet_az1 = "us-east-1a"
  subnet_az2 = "us-east-1b"

  #Version of Kubernetes to be used for the EKS cluster
  eks_version = "1.32"

  #Only the below specific names are supported to create a cluster in kodekloud playgrounds
  eks_name          = "demo-eks"
  cluster_role_name = "eksClusterRole"
}