data "aws_eks_cluster" "eks_cluster" {
  name = local.eks_name 

  depends_on = [ aws_eks_cluster.eks ]
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = local.eks_name

  depends_on = [ aws_eks_cluster.eks ]
}

