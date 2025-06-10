#Attach the EBS CSI Driver to the nodeinstane role once created
resource "aws_iam_role_policy_attachment" "node_instance_role_ebs_pol" {
  #Since we get the complete node instance role arn, we need to trim it down so that we only pass the role name 
  role = split("/",aws_cloudformation_stack.nodegroup.outputs["NodeInstanceRole"])[1]
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  depends_on = [ aws_cloudformation_stack.nodegroup ]
}

#Commenting because the addon will go into degraded state if no nodes available to schedule the ebs csi pods, causing terraform execution to keep running forever 
# resource "aws_eks_addon" "ebs-csi" {
#   cluster_name = aws_eks_cluster.eks.name
#   addon_name = "aws-ebs-csi-driver"
#   addon_version = "v1.44.0-eksbuild.1" 
#   depends_on = [ aws_iam_role_policy_attachment.node_instance_role_ebs_pol ]
# }
