output "instance_ip" {
  value = module.wordpress.wordpress_public_ips
}


output "AppLoadBalance_address" {
  value = module.wordpress.wordpress_alb
}
