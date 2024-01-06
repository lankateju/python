#below setup involved
#created a vpc with 3 public and 3 private subnets
#created EC2 instances
#created security groups for kubernetes
#created IAM roles,IAM policies,attached Roles
#created EKS cluster
#created node group

#This section specifies that we are using the AWS provider and sets the region to "ap-south-2" (Asia Pacific, Hyderabad).
#It tells Terraform where to create and manage resources.

provider "aws" {
  region = "ap-south-2"
}

// Creating VPC
#This defines a Virtual Private Cloud (VPC) with an IP address range of "10.11.0.0/16". 
#The VPC is like a private network in which we'll place our resources.

resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.11.0.0/16"
}

// Creating Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.4.0/24"
  availability_zone = "ap-south-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.5.0/24"
  availability_zone = "ap-south-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.6.0/24"
  availability_zone = "ap-south-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-3"
  }
}

// Creating Internet Gateway
#An internet gateway is created and associated with the VPC. 
#This allows resources in the VPC to communicate with the internet.
resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "demo-igw"
  }
}

// Creating Route Table for Public Subnets
#setting up a route table for the public subnets, allowing traffic to the internet via the internet gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

// Associating Public Subnets with the Public Route Table

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_rt.id
}

// Creating Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.7.0/24"
  availability_zone = "ap-south-2a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.8.0/24"
  availability_zone = "ap-south-2b"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.11.9.0/24"
  availability_zone = "ap-south-2c"

  tags = {
    Name = "private-subnet-3"
  }
}
 
// Creating Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "private-rt"
  }
}

// Associating Private Subnets with the Private Route Table
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_rt.id
}

// Creating Security Group
#This setup is used for allowing SSH access to instances within the VPC.
resource "aws_security_group" "demo-vpc-sg" {
  name        = "allow_tls"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

// Creating NAT Gateway
#NAT Gateway associated with the public subnet. The NAT Gateway allows instances in private subnets to access the internet.
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_instance.nat_instance.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

// Creating an Elastic IP for NAT Gateway
#Elastic IP for the NAT Gateway, which helps maintain a consistent public IP address for the NAT Gateway instance.
resource "aws_instance" "nat_instance" {
  ami                    = "ami-0a0f1259dd1c90938"
  instance_type          = "t2.micro"
  key_name               = "teju109152_linux"  # Replace with your actual key pair name
  subnet_id              = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  tags = {
    Name = "nat-instance"
  }
}

Creating an AWS EC2 Instance
resource "aws_instance" "demo_server" {
  ami                    = "ami-0a0f1259dd1c90938"
  key_name               = "teju09152_linux"  # Replace with your actual key pair name
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.demo-vpc-sg.id]
}

// Creating security groups for kubernetes

resource "aws_security_group" "worker_node_sg" {
  name        = "eks-test"
  description = "Allow ssh inbound traffic"
  vpc_id      =  aws_vpc.demo-vpc.id

  ingress {
    description      = "ssh access to public"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

//creating roles,policies and attaching roles
#IAM Roles for EKS Master and Worker Nodes

resource "aws_iam_role" "master" {
  name = "ed-eks-master"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role" "worker" {
  name = "ed-eks-worker"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "autoscaler" {
  name   = "ed-eks-autoscaler-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "x-ray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.worker.name
}
resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "worker" {
  depends_on = [aws_iam_role.worker]
  name       = "ed-eks-worker-new-profile"
  role       = aws_iam_role.worker.name
}

#creating an AWS EKS cluster
resource "aws_eks_cluster" "eks" {
  name = "ed-eks-01"
  role_arn = aws_iam_role.master.arn 
#Associates the IAM role created earlier (aws_iam_role.master) with the EKS cluster.
#This role allows the EKS service to manage the cluster.

  vpc_config {
    subnet_ids = [aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id,
    ]
  }
  #Specifies the subnet IDs in which the EKS cluster will be deployed. In this case, it uses three private subnets
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]

}
#the creation of the EKS cluster depends on the successful attachment of IAM policies to the IAM role
# creating an AWS EKS node group

resource "aws_eks_node_group" "backend" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "dev"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids = [aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id,
    ]
  capacity_type = "ON_DEMAND"
  disk_size = "20"
  instance_types = ["t2.small"]
  remote_access {
    ec2_ssh_key = "rtp-03"
    source_security_group_ids = [aws_security_group.demo-vpc-sg.id]
  } 
  
  labels =  tomap({env = "dev"})
  
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
   security_group_ids = [aws_security_group.demo-vpc-sg.id]
   vpc_id = aws_vpc.demo-vpc.id
    subnet_ids = [aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id,
    ]
}

# Auto Scaling Group for public subnet
resource "aws_autoscaling_group" "public_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]
  launch_configuration = aws_launch_configuration.public_lc.id

  tag {
    key                 = "Name"
    value               = "public-asg-instance"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
}

# Launch Configuration for public ASG
resource "aws_launch_configuration" "public_lc" {
  name                 = "public-lc"
  image_id             = "ami-0a0f1259dd1c90938"
  instance_type        = "t2.micro"
  key_name             = "teju09152_linux"
  security_groups      = [aws_security_group.demo-vpc-sg.id]
  associate_public_ip_address = true
}

# Application Load Balancer for public subnet
resource "aws_lb" "public_alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-vpc-sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]

  enable_deletion_protection = false

  enable_http2        = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "public-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "public_tg" {
  name        = "public-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.demo-vpc.id
  target_type = "instance"

  health_check {
    path        = "/"
    protocol    = "HTTP"
    port        = "traffic-port"
    interval    = 30
    timeout     = 5
  }

  depends_on = [aws_lb.public_alb]
}

# ALB Listener
resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response   = {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }

  depends_on = [aws_lb_target_group.public_tg]
}

# ASG Attachment to Target Group
resource "aws_lb_target_group_attachment" "public_asg_attachment" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_autoscaling_group.public_asg.name
}

# Auto Scaling Group for private subnet
#Auto Scaling Groups automatically adjust the number of instances in response to changes in demand or other criteria. 
#This ensures high availability and fault tolerance.
resource "aws_autoscaling_group" "private_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.private_subnet_3.id]
  launch_configuration = aws_launch_configuration.private_lc.id

  tag {
    key                 = "Name"
    value               = "private-asg-instance"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
}

# Launch Configuration for private ASG
# The launch configuration specifies settings for instances launched in the Auto Scaling Group, including the Amazon Machine Image (AMI), instance type, security groups, etc.
resource "aws_launch_configuration" "private_lc" {
  name                 = "private-lc"
  image_id             = "ami-0a0f1259dd1c90938"
  instance_type        = "t2.micro"
  key_name             = "teju09152_linux"
  security_groups      = [aws_security_group.demo-vpc-sg.id]
}

# Application Load Balancer for private subnet
#  Creates an Application Load Balancer (ALB) for distributing incoming traffic across instances in the private subnets.
resource "aws_lb" "private_alb" {
  name               = "private-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-vpc-sg.id]
  subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.private_subnet_3.id]

  enable_deletion_protection = false

  enable_http2        = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "private-alb"
  }
}

# ALB Target Group for private subnet
# Defines a target group for instances in the private subnets that the ALB routes traffic to.
# Target groups are used to route traffic to instances based on health checks. 
# They are an essential component of load balancing in AWS.
resource "aws_lb_target_group" "private_tg" {
  name        = "private-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.demo-vpc.id
  target_type = "instance"

  health_check {
    path        = "/"
    protocol    = "HTTP"
    port        = "traffic-port"
    interval    = 30
    timeout     = 5
  }

  depends_on = [aws_lb.private_alb]
}

# ALB Listener for private subnet
# Creates a listener for the ALB to process incoming traffic on a specified port.
# Listeners define the rules for routing traffic to target groups. 
# In this case, it listens on port 80 and directs traffic to the private target group.
resource "aws_lb_listener" "private_listener" {
  load_balancer_arn = aws_lb.private_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response   = {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }

  depends_on = [aws_lb_target_group.private_tg]
}

# ASG Attachment to Target Group for private subnet
# Attaches the Auto Scaling Group instances to the target group used by the ALB.
# This ensures that instances launched by the ASG are considered targets for the ALB
# And traffic is directed to these instances based on the rules defined in the target group.
resource "aws_lb_target_group_attachment" "private_asg_attachment" {
  target_group_arn = aws_lb_target_group.private_tg.arn
  target_id        = aws_autoscaling_group.private_asg.name
}



