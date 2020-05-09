###
output "this_lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.networking_alb.this_lb_dns_name
}
