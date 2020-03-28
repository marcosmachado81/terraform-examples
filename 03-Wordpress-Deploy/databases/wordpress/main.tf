resource "aws_db_subnet_group" "rds-private-subnet" {
  name = "rds-wordpress-subnet"
  subnet_ids = var.subnet_private_ids
  tags = {
     Name         = "rds-wordpress-subnet"
     Environment  = var.environment
     Team         = var.team
     CostCenter   =  var.costCenter
  }
}

resource "aws_security_group" "rds-sg" {
  name   = "my-rds-sg"
  vpc_id = var.vpc_id

  tags = {
     Name         = "my-rds-sg"
     Environment  = var.environment
     Team         = var.team
     CostCenter   =  var.costCenter
  }

}

# Ingress Security Port 3306
resource "aws_security_group_rule" "mysql_inbound_access" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds-sg.id
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = var.all_subnet_cidr_blocks

}

resource "aws_db_instance" "mySQL" {
  identifier             = "my-db-wordpress"
  engine                 = var.engine
  engine_version         = var.engine_version
  port                   = 3306
  name                   = var.dbname
  username               = var.dbuser
  password               = var.dbpassword
  instance_class         = var.db_instance_class
  allocated_storage      = var.storage_Size
  skip_final_snapshot    = true
  license_model          = "general-public-license"
  db_subnet_group_name   = aws_db_subnet_group.rds-private-subnet.id
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  publicly_accessible    = false
  #parameter_group_name   = aws_db_parameter_group.example.id
  #option_group_name      = aws_db_option_group.example.id

  tags = {
    Name         = "My-DB-Wordpress"
    Environment  = var.environment
    Team         = var.team
    CostCenter   =  var.costCenter
  }
}
