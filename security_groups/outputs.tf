output "agent_sg_id" {
    description = "Agent security group ID."
    value = aws_security_group.worker_windows.id
}