#Create a simple VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(local.aws_tags, {"Name" = "EKS-VPC"})
}

#Create Internet gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = merge(local.aws_tags, {"Name" = "EKS-IGW"})
}

#Subnet 1
resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.64.0/19"
  availability_zone = local.subnet_az1
  map_public_ip_on_launch = true

  tags = merge(local.aws_tags, {
    Name = "${local.aws_tags.Environment}-public-${local.subnet_az1}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.aws_tags.Environment}-${local.eks_name}" = "owned"
  })
}

#Subnet 2 
resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.64.0/19"
  availability_zone = local.subnet_az2
  map_public_ip_on_launch = true

  tags = merge(local.aws_tags, {
    Name = "${local.aws_tags.Environment}-public-${local.subnet_az2}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.aws_tags.Environment}-${local.eks_name}" = "owned"
  })
}

#Creating a route table with route for Public subnets, that will redirect request to internet_gateway if destination CIDR is 0.0.0.0/0
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = merge(local.aws_tags, {
    Name = "${local.aws_tags.Environment}-public"
  })
}

#Associate public routes to the public subnets
resource "aws_route_table_association" "public-route1" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-route2" {
  subnet_id = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.public.id
}

