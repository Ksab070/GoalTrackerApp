1. Add AWS creds to AWSCLI using "aws configure".

2. Run the terraform and wait for the cluster to create successfully. 

3. After Terraform completes, note the output values for **NodeAutoScalingGroup**, **NodeInstanceRole**, and **NodeSecurityGroup**. You will see something similar to this:

```
Outputs:

NodeAutoScalingGroup = "demo-eks-stack-NodeGroup-UUJRINMIFPLO"
NodeInstanceRole = "arn:aws:iam::058264119838:role/eksWorkerNodeRole"
NodeSecurityGroup = "sg-003010e8d8f9f32bd"
```

4. Create a Kubeconfig for kubectl

```
aws eks update-kubeconfig --region us-east-1 --name demo-eks
```

5. Join the cluster nodes

-> Download the node authentication ConfigMap

```
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/aws-auth-cm.yaml
```

-> Edit the ConfigMap YAML to add in the **NodeInstanceRole** obtained from terraform, Replace the placeholder text <ARN of instance role (not instance profile)> with the value of **NodeInstanceRole** from Terraform, then save and exit the editor. The ConfigMap looks like this before editing:

```
apiVersion: v1
kind: ConfigMap
metadata:
name: aws-auth
namespace: kube-system
data:
mapRoles: |
  - rolearn: <ARN of instance role (not instance profile)> # <- EDIT THIS
    username: system:node:{{EC2PrivateDNSName}}
    groups:
      - system:bootstrappers
      - system:nodes
```

6. Apply the configmap using kubectl
```
kubectl apply -f aws-auth-cm.yaml
```

7. Wait 2 - 4 minutes, for the nodes to join the cluster

8. Verify if the nodes joined properly
```
kubectl get nodes -owide
```