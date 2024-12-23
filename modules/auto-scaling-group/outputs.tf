output "asg_id" {
  description = "Autoscaling group id"
  value       = aws_autoscaling_group.autoscaling_group.id
}