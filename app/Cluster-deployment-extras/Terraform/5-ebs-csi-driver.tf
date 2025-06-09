data "aws_iam_policy_document" "ebs_csi_iam_role_doc" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["pods.eks.amazonaws.com"]
        }

        actions = ["sts:AssumeRole", "sts:TagSession"]
    }
}

resource "aws_iam_role" "ebs_csi_iam_role" {
  name = "${aws_eks_cluster.eks.name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_iam_role_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_permission_ebs_csi" {
  role = aws_iam_role.ebs_csi_iam_role.arn
  
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "aws-ebs-csi-driver"
  addon_version = "v1.44.0-eksbuild.1" 
  service_account_role_arn = 
} 
