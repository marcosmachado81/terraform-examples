
locals {
  environment = terraform.workspace

  vpc_id_list = {
    "default"     = module.network.testing_vpc_id
    "production"  = module.network.vpc_id
    "testing"     = module.network.testing_vpc_id
  }

  subnet_public_ids_list = {
    "default" =     module.network.subnet_public_testing_ids
    "production" =  module.network.subnet_public_ids
    "testing" =     module.network.subnet_public_testing_ids
  }

  subnet_private_ids_list = {
    "default" =     module.network.subnet_private_testing_ids
    "production" =  module.network.subnet_private_ids
    "testing" =     module.network.subnet_private_testing_ids
  }

  all_subnet_cidr_blocks_list = {
    "testing" = concat(module.network.subnet_public_testing_cidr_blocks,module.network.subnet_private_testing_cidr_blocks)
    "production" = concat(module.network.subnet_public_cidr_blocks,module.network.subnet_private_cidr_blocks)
    "default" = concat(module.network.subnet_public_testing_cidr_blocks,module.network.subnet_private_testing_cidr_blocks)
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
  dbuser                  = "db_user_wordpress"
  dbpassword              = "536e362c7cb3e1cde2a674637447fc06"
  bastion_instance_type   = "t2.micro"
  instance_type           = lookup(local.instance_type_list,local.environment)
  subnet_private_ids      = lookup(local.subnet_private_ids_list,local.environment)
  all_subnet_cidr_blocks  = lookup(local.all_subnet_cidr_blocks_list,local.environment)
  subnet_public_ids       = lookup(local.subnet_public_ids_list,local.environment)
  storage_size            = lookup(local.storage_size_list,local.environment)
  db_instance_class        = lookup(local.db_instance_class_list,local.environment)

}

module "core" {
  source = "./infrastrucutre/core"
}

module "network" {
  source                = "./infrastrucutre/network"

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
  dbuser                  = local.dbuser
  dbpassword              = local.dbpassword
  wordpress_address       =module.wordpress.wordpress_alb

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

  #Application variables
  vpc_id            = local.vpc_id
  subnet_public_ids = local.subnet_public_ids
  ingress_ports     = [80,22]
  total_instances   = 1
  ami_id            = module.core.ami_default.id
  instance_type     = local.instance_type
  key_name          = "MacMini"
  environment       = local.environment
  #depends_on = [ module.network, module.core ]
  dbname           = local.dbname
  dbuser           = local.dbuser
  dbpassword       = local.dbpassword
  dbhost           = module.wordpress_database.db_address


  wp_user_admin     = "admin"
  wp_user_password  = "75622e9c6b10dee650fc5e8a9cae89b1"
  wp_user_mail      = "teste@teste.gor"
  wp_locale         = "pt_BR"

  #loadBalance Variables
  bucket_name       = "loadbalance-staticwebsite-0394902"
  bucket_prefix     = "LB-Logs"
  health_path       = "/health.html"

}
