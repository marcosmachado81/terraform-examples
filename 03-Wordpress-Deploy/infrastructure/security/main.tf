/*
Get data from ssm parameters


/*
MODIFY THE PASSWORDS for DATABASE and others passwords for System Manager Parameters
Create a file named ssm_parameters and use data to request the parameters

Create the parameters

/wordpress/testing/db_user
/wordpress/testing/db_pass

/wordpress/production/db_user
/wordpress/production/db_pass securestring

/wordpress/testing/wp_user
/wordpress/testing/wp_pass djedk45@

/wordpress/production/wp_user
/wordpress/production/wp_pass securestring

*/


data "aws_ssm_parameter" "db_user" {
  name = "/wordpress/${var.environment}/db_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "/wordpress/${var.environment}/db_pass"
}

data "aws_ssm_parameter" "wp_user" {
  name = "/wordpress/${var.environment}/wp_user"
}

data "aws_ssm_parameter" "wp_password" {
  name = "/wordpress/${var.environment}/wp_pass"
}
