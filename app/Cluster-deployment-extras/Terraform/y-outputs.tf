output "node_instance_role" {
  value = aws_cloudformation_stack.nodegroup.outputs["NodeInstanceRole"]
}

output "node_autoscaling_group" {
  value = aws_cloudformation_stack.nodegroup.outputs["NodeAutoScalingGroup"]
}

output "node_security_group" {
  value = aws_cloudformation_stack.nodegroup.outputs["NodeSecurityGroup"]
}


