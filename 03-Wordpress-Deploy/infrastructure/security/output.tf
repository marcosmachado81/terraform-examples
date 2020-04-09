output "dbuser" {
  value = data.aws_ssm_parameter.db_user.value
}

output "dbpassword" {
  value = data.aws_ssm_parameter.db_password.value
}

output "wpuser" {
  value = data.aws_ssm_parameter.wp_user.value
}

output "wppassword" {
  value = data.aws_ssm_parameter.wp_password.value
}
