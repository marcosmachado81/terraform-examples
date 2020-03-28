output "wordpress_public_ips" {
  value = aws_instance.WordpressInstance.*.public_ip
}

output "wordpress_alb" {
  value = aws_lb.ALB-Wordpress.dns_name
}
