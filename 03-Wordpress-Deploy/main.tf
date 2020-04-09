/*

*/
locals {
  environment = terraform.workspace

  vpc_id_list = {
    "default"     = module.network.testing_vpc_id
    "production"  = module.network.vpc_id
    "testing"     = module.network.testing_vpc_id
  }

  subnet_public_ids_list = {
    "default"    =  module.network.subnet_public_testing_ids
    "production" =  module.network.subnet_public_ids
    "testing"    =  module.network.subnet_public_testing_ids
  }

  subnet_private_ids_list = {
    "default"    =  module.network.subnet_private_testing_ids
    "production" =  module.network.subnet_private_ids
    "testing"    =  module.network.subnet_private_testing_ids
  }

  all_subnet_cidr_blocks_list = {
    "testing"    = concat(module.network.subnet_public_testing_cidr_blocks,module.network.subnet_private_testing_cidr_blocks)
    "production" = concat(module.network.subnet_public_cidr_blocks,module.network.subnet_private_cidr_blocks)
    "default"    = concat(module.network.subnet_public_testing_cidr_blocks,module.network.subnet_private_testing_cidr_blocks)
  }

  instance_type_list = {
    "default"     = "t2.micro"
    "production"  = "t2.micro"
    "testing"     = "t2.micro"
  }

  db_instance_class_list = {
    "default"     = "db.t2.micro"
    "production"  = "db.t2.micro"
    "testing"     = "db.t2.micro"
  }

  storage_size_list = {
    "default"     = 20
    "testing"     = 20
    "production"  = 20
  }

  vpc_id                  = lookup(local.vpc_id_list,local.environment)
  dbname                  = "db_wordpress"
  bastion_instance_type   = "t2.micro"
  instance_type           = lookup(local.instance_type_list,local.environment)
  subnet_private_ids      = lookup(local.subnet_private_ids_list,local.environment)
  all_subnet_cidr_blocks  = lookup(local.all_subnet_cidr_blocks_list,local.environment)
  subnet_public_ids       = lookup(local.subnet_public_ids_list,local.environment)
  storage_size            = lookup(local.storage_size_list,local.environment)
  db_instance_class       = lookup(local.db_instance_class_list,local.environment)
  region                  = "eu-west-3"

}

module "core" {
  source = "./infrastructure/core"
}

module "security" {
  source = "./infrastructure/security"
  environment = local.environment

}

module "network" {
  source                = "./infrastructure/network"

  moduleIdentification  = "Infra-Network"
  team                  = "Operations"
  costCenter            = "IT"

  vpc_cidr_block        = "10.0.0.0/16"
  prefix_cidr_block     = "10.0"

  vpc_cidr_block_testing = "172.16.0.0/16"
  prefix_cidr_block_testing = "172.16"
}

module "wordpress_database" {
  source = "./databases/wordpress"
  moduleIdentification  = "DB-Wordpress"
  team                  = "DB"
  costCenter            = "HR"
  environment           = local.environment

  subnet_public_id      = local.subnet_public_ids[0]
  subnet_private_ids    = local.subnet_private_ids
  vpc_id                  = local.vpc_id
  all_subnet_cidr_blocks  = local.all_subnet_cidr_blocks
  dbname                  = local.dbname
  dbuser                  = module.security.dbuser
  dbpassword              = module.security.dbpassword
  #wordpress_address       = module.wordpress.wordpress_alb

  engine                 = "mysql"
  engine_version         = "5.7.22"
  db_instance_class      = local.db_instance_class
  storage_Size           = local.storage_size

}

module "wordpress" {
  source = "./applications/wordpress"

  moduleIdentification  = "App-Wordpress"
  team                  = "Dev"
  costCenter            = "HR"

  region                = local.region

  #Application variables
  vpc_id            = local.vpc_id
  subnet_public_ids = local.subnet_public_ids
  //ingress_ports     = [80,22,2049]
  #One instance is create by aws_instance just to configure the wordpress environment.
  #this instance will install and copy files to S3 and EFS mounts.
  #After that the instance will shutdown and terminate.
  #To increase the number of instances in alb use auto scale variables
  total_instances   = 1
  ami_id            = module.core.ami_default.id
  instance_type     = local.instance_type
  key_name          = "MacMini"
  environment       = local.environment
  #depends_on = [ module.network, module.core ]
  dbname           = local.dbname
  dbuser           = module.security.dbuser
  dbpassword       = module.security.dbpassword
  dbhost           = module.wordpress_database.db_address

  wp_content_bucket_name   = "my-wordpress-uploads-10294"
  wordpress_wp_content     = "/var/www/wp-uploads"

  #wordpress user,password,admin e-mail and locale
  wp_user_admin     = module.security.wpuser
  wp_user_password  = module.security.wppassword
  wp_user_mail      = "teste@teste.gor"
  wp_locale         = "pt_BR"

  #loadBalance variables
  load_balance_bucket_name = "loadbalance-staticwebsite-0394902"
  bucket_prefix            = "LB-Logs"
  health_path              = "/health.html"
  sticky_session           = false
  //ingress_ports_loadbalance = [ 80 ]

  #Auto Scaling variables
  auto_scaling_min_size         = 1
  auto_scaling_desired_capacity = 1
  auto_scaling_max_size         = 2
  auto_scale_cooldown           = 60
  auto_scale_capacityUP         = 1
  auto_scale_capacityDOWN       = -1
  #Auto Scaling metrics
  #for scale out up
  as_metric_up_evaluation_periods = "1"
  as_metric_up_period             =  "60"
  as_metric_up_threshold          = "50"

  #scale out down
  as_metric_down_evaluation_periods = "1"
  as_metric_down_period             = "60"
  as_metric_down_threshold          = "50"


}
