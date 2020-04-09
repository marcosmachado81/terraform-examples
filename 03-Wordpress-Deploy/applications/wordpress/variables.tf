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
//variable "ingress_ports" {}


variable "wp_content_bucket_name" {}
variable "wordpress_wp_content" {}

#variables for loadBalance.tf
variable "load_balance_bucket_name" {}
variable "bucket_prefix" {}
variable "health_path" {}
variable "wp_locale" {}
variable "region" {}
variable "sticky_session" {}
//variable "ingress_ports_loadbalance" {}

#AutoScaling variables
variable "auto_scaling_min_size" {}
variable "auto_scaling_desired_capacity" {}
variable "auto_scaling_max_size" {}
variable "auto_scale_cooldown" {}
variable "auto_scale_capacityUP" {}
variable "auto_scale_capacityDOWN" {}

#AS metrics
variable "as_metric_up_evaluation_periods" {}
variable "as_metric_up_period" {}
variable "as_metric_up_threshold" {}

variable "as_metric_down_evaluation_periods" {}
variable "as_metric_down_period" {}
variable "as_metric_down_threshold" {}
