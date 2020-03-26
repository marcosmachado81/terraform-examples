output "loadbalance_address" {
  value = aws_lb.ALB-WebSite.dns_name
}

output "instance_ip" {
  value = aws_instance.WebServer.*.public_ip
}
