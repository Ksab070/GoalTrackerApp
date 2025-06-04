#Create the role for the EKS cluster
resource "aws_iam_role" "eks-cluster" {
  name = local.cluster_role_name

  # This IAM policy is required so that the EKS can take IAM roles, this is a trust policy, not a permission policy
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "eks.amazonaws.com"
            }
        }
    ]
}
POLICY
}

#Attach the permission policy to the role
resource "aws_iam_role_policy_attachment" "cluster-policy" {
  #policy given here is a permission policy, which defines the permissions for the AWS 
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks-cluster.name
}

#This is required for POSTGRESQL
resource "aws_iam_role_policy_attachment" "ebs-csi-driver-policy" {
  #policy given here is a permission policy, which defines the permissions for the AWS 
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role = aws_iam_role.eks-cluster.name
}


resource "aws_eks_cluster" "eks" {
  name = "${local.eks_name}"
  role_arn = aws_iam_role.eks-cluster.arn
  version = local.eks_version

  vpc_config {
    #Disabling private access to the EKS cluster using Private endpoint, worker notes can't connect to the control plane (if cluster is hosted in private subnet) unless NAT gateway / Internet gateway is setup
    endpoint_private_access = false
    endpoint_public_access = true
    
    #Hosting the cluster in private subnets
    subnet_ids = [ aws_subnet.subnet_1.id, aws_subnet.subnet_2.id ]
  }

  access_config {
    #Settting the authentication mode to API and Config map 
    authentication_mode = "API_AND_CONFIG_MAP"
    #Cluster creator will get admin permissions
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [ aws_iam_role_policy_attachment.cluster-policy ]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "aws-ebs-csi-driver"
}