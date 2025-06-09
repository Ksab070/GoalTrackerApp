data "aws_eks_cluster" "eks_cluster" {
  name = local.eks_name 

  depends_on = [ aws_eks_cluster.eks ]
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = local.eks_name

  depends_on = [ aws_eks_cluster.eks ]
}

data "aws_cloudformation_stack" "nodegroup_datasrc" {
  name = aws_cloudformation_stack.nodegroup.name
}

data "template_file" "node-instance-role-arn" {
  template = file("${path.module}/aws-auth-cm.yaml.tmpl")
  vars = {
    node-instance-role-arn = aws_cloudformation_stack.nodegroup.outputs["NodeInstanceRole"]
  }
}

data "aws_iam_openid_connect_provider" "oidc-provider"{
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}