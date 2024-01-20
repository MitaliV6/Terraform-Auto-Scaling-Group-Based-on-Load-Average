output "load_balancer_url" {
  description = "The URL of the created AWS Load Balancer"
  value       = aws_lb.asg-terraform-lb.dns_name
}