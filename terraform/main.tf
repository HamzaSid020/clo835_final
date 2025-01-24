provider "aws" {
  region = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyAssignmentVPC"
  }
}

# Create a public subnet in the new VPC
resource "aws_subnet" "my_public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MyPublicSubnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyInternetGateway"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0" # Route all traffic to the internet
    gateway_id     = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyPublicRouteTable"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create ECR repositories for the web application and MySQL images
resource "aws_ecr_repository" "web_app_repo" {
  name = "my-web-app-repo"
}

resource "aws_ecr_repository" "mysql_repo" {
  name = "mysql-repo"
}

# Create a security group to allow traffic to the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the new subnet
resource "aws_instance" "web_instance" {
  ami                    = "ami-043a5a82b6cf98947" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Update packages
              yum update -y

              # Install Docker
              amazon-linux-extras install docker
              service docker start
              usermod -a -G docker ec2-user

              # Log in to ECR
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.web_app_repo.repository_url}
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.mysql_repo.repository_url}

              # Pull the images from ECR
              docker pull ${aws_ecr_repository.web_app_repo.repository_url}:latest
              docker pull ${aws_ecr_repository.mysql_repo.repository_url}:latest

              # Run Docker containers
              docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=rootpassword ${aws_ecr_repository.mysql_repo.repository_url}:latest
              docker run -d --name webapp -p 80:80 -e DB_HOST=mysql -e DB_PORT=3306 ${aws_ecr_repository.web_app_repo.repository_url}:latest
            EOF

  tags = {
    Name = "MyWebApp-Instance"
  }
}