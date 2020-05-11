###
output "this_lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.this_lb_dns_name
}


output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = module.alb.target_group_arns
}
