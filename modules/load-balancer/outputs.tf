output "alb_tg_arn" {
  description = "Load balancer target group ARN"
  value       = aws_lb_target_group.load_balancer_tg.arn
}

output "alb_dns_name" {
  description = "DNS name for the load balancer"
  value       = aws_lb.load_balancer.dns_name
}