output "server_public_subnet_id" {
    description = "ID of the public subnet"
    value = aws_subnet.jenkins_public_subnet.id
}

output "server_vpc_id" {
    description = "ID of the VPC"
    value = aws_vpc.server_vpc.id
}

output "worker_public_subnet_id" {
    description = "ID of the public subnet"
    value = aws_subnet.agent_public_subnet.id
}

output "worker_vpc_id" {
    description = "ID of the VPC"
    value = aws_vpc.worker_vpc.id
}