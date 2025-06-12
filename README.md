# Capstone: GoalTracker-App project

The repo is for the Capstone project of K8s Hindi Bootcamp by Saiyam. 

Ensure pre-requisites are installed, if not, refer below (Commands are given assuming you are on an Ubuntu machine):

#### AWS CLI 
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### Terraform
```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt-get install terraform
```

#### Docker

```
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### Kubectl 
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

===============================================

# Project Structure 
```
.
├── Cluster-deployment-extras              # Additional tools and configurations for infrastructure provisioning
│   ├── Shell-scripts                      # Shell scripts for cluster setup
│   │   └── install-prerequisites.sh      # Installs required tools and dependencies
│   └── Terraform                          # Infrastructure as Code for AWS EKS cluster
│       ├── 0-locals.tf                   # Variable definitions and local values
│       ├── 1-terraform.tf                # Terraform backend and provider configuration
│       ├── 2-vpc.tf                      # VPC and networking components
│       ├── 3-eks.tf                      # EKS cluster definition
│       ├── 4-nodegroup.tf               # EKS worker node group setup
│       ├── 5-ebs-csi-driver.tf          # EBS CSI driver integration for persistent storage
│       ├── aws-auth-cm.yaml.tmpl        # Template for creating the AWS authentication ConfigMap
│       ├── datasources.tf               # Terraform data sources
│       ├── iam_policy.json              # IAM policy document for roles and permissions
│       └── outputs.tf                   # Outputs generated post-deployment
├── Code                                  # Source code for the demo application
│   ├── app.py                           # Main Python web application (Written in Flask)
│   ├── Dockerfile                       # Dockerfile to containerize the app
│   ├── load.js                          # JS file for load testing
│   ├── requirements.txt                 # Python package dependencies
│   └── templates
│       └── index.html                   # HTML template served by the Flask app
├── deploy                                # Deployment-related files and test client
│   ├── democlient.yaml                  # Client files for demo 
│   └── deploy.yaml                      # Kubernetes deployment file for the application
├── Manifests                             # Kubernetes manifests for deploying and configuring services
│   ├── 1.yaml                           # Application deployment manifest
│   ├── aws-auth-cm.yaml                # AWS authentication config for EKS
│   ├── certificate.yaml                # Certificate configuration (For Cert-manager)
│   ├── cluster-issuer-prod.yaml        # Cluster-wide certificate issuer for production
│   ├── configmap.yaml                  # Application configuration including DB_name, DB_username, and DB_port 
│   ├── deploy.yaml                     # Deployment manifest for core application
│   ├── hpa.yaml                        # Horizontal Pod Autoscaler config
│   ├── ingress.yaml                    # Ingress resource definition
│   ├── nginx-ingress-controller.yaml  # NGINX ingress controller setup
│   ├── postgres-cluster.yaml          # PostgreSQL database deployment
│   ├── secret.yaml                     # Kubernetes Secret definitions (Base64 encoded)
│   └── service.yaml                    # Kubernetes Service definitions for external access on port 80
├── tmpl                                  # Jinja2 template files
│   └── deploy.j2                        # Jinja2 template for deployment manifest
└── README.md                             # Main project documentation
```

===============================================

# Steps to deploy the app

1. Configure AWS - CLI using the following command: `aws configure`

2. Run the Terraform and wait for the Cluster & Nodes to create successfully

3. Create a Kubeconfig for kubectl to connect to your cluster
```
aws eks update-kubeconfig --region us-east-1 --name demo-eks
```

4. TF code will populate the aws-auth-cm.yaml file using template() function, apply the configmap for nodes to be able to join the cluster (It may take 2 - 4 minutes for nodes to join the cluster)

```
kubectl apply -f aws-auth-cm.yaml
```

5. Once kubeconfig is setup set the gp2 storage class to default

```
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

6. Install the AWS-EBS-CSI Driver to your cluster, go inside the Terraform folder again, uncomment aws_eks_addon.ebs-csi resource and run TF again

7. Navigate to code folder, then build and push the image
```
docker build --no-cache --platform=linux/amd64 -t ttl.sh/subhan/demo:10h .   

docker push ttl.sh/subhan/demo:10h
```

8. Install Cloudnative PG 
```
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-1.23.1.yaml
```

9. Create postgresql DB cluster
```
kubectl apply -f secret.yaml

kubectl apply -f postgres-cluster.yaml
```

10. Go inside the postgres container and create the application's table 
```
kubectl exec -it my-postgresql-1 -- psql -U postgres -c "ALTER USER goals_user WITH PASSWORD 'new_password';"

kubectl exec -it my-postgresql-1 -- bash

PGPASSWORD='new_password' psql -h 127.0.0.1 -U goals_user -d goals_database -c "CREATE TABLE goals (id SERIAL PRIMARY KEY, goal_name VARCHAR(255) NOT NULL);"
```

11. Deploy the application 
```
kubectl apply -f deploy.yaml
```

12. Add auto-scaling to the application
```
kubectl apply -f hpa.yaml
```

13. Install Cert manager and Nginx ingress controller 
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml

kubectl apply -f nginx-ingress-controller.yaml
```

14. Create Ingress and give External access to your application with AWS NLB
```
kubectl apply -f service.yaml

kubectl apply -f cluster-issuer-prod.yaml

kubectl apply -f certificate.yaml

kubectl apply -f ingress.yaml 
```

15. You will get a DNS name from the details of nginx-ingress-controller's service, you can check it by `kubectl get svc -A` example:
```
ingress-nginx   ingress-nginx-controller             LoadBalancer   172.20.96.248    a2fa2b79403a04440887e46105ccff39-bbcd0c68b829138b.elb.us-east-1.amazonaws.com   80:32372/TCP,443:30695/TCP   134m
```
Map this DNS name to your domain by creating a CNAME record

===============================================

## Install Metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

===============================================

# GithubActions and ArgoCD

## Steps 
1. Create .github/workflows folder 
2. Create a file build-push-image.yaml 
3. Create a jinja template app/tmpl/deploy.j2
4. Create deployment file - /app/deploy/deploy.yaml
5. Create GitHub Actions secret - DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD
6. Make sure your actions have push access as well. 

## Install ArgoCd
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get secret -n argocd argocd-initial-admin-secret -oyaml
```
