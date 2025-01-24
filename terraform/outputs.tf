
output "web_app_repo_url" {
  description = "Web app ECR repository URL"
  value       = aws_ecr_repository.web_app_repo.repository_url
}

output "mysql_repo_url" {
  description = "MySQL ECR repository URL"
  value       = aws_ecr_repository.mysql_repo.repository_url
}

output "web_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_instance.public_ip
}

# Output for the EC2 instance ID
output "web_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_instance.id
}

# Outputs for the created resources
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.my_vpc.id
}

output "subnet_id" {
  description = "ID of the created public subnet"
  value       = aws_subnet.my_public_subnet.id
}


