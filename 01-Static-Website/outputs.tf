output "instance_ip" {
  value = aws_instance.WebServer.*.public_ip
}
