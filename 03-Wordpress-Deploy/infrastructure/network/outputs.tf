output "vpc_id" {
  value = aws_vpc.principal.id
}

output "testing_vpc_id" {
  value = aws_vpc.testing.id
}

output "subnet_public_ids" {
  value = aws_subnet.public.*.id
}

output "subnet_public_testing_ids" {
  value = aws_subnet.public_testing.*.id
}

output "subnet_private_ids" {
  value = aws_subnet.private.*.id
}

output "subnet_private_testing_ids" {
  value = aws_subnet.private_testing.*.id
}

output "subnet_private_testing_cidr_blocks" {
  value = aws_subnet.private_testing.*.cidr_block
}

output "subnet_public_testing_cidr_blocks" {
  value = aws_subnet.public_testing.*.cidr_block
}

output "subnet_private_cidr_blocks" {
  value = aws_subnet.private.*.cidr_block
}

output "subnet_public_cidr_blocks" {
  value = aws_subnet.public.*.cidr_block
}
