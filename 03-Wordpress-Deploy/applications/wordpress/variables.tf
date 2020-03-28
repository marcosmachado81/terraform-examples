variable "moduleIdentification" {}
variable "team" {}
variable "costCenter" {}

variable "subnet_public_ids" {}
variable "total_instances" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "environment" {}

variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
variable "dbhost" {}


variable "wp_user_admin" {}
variable "wp_user_password" {}
variable "wp_user_mail" {}

variable "vpc_id" {}
variable "ingress_ports" {}


#variables for loadBalance.tf
variable "bucket_name" {}
variable "bucket_prefix" {}
variable "health_path" {}
variable "wp_locale" {}
