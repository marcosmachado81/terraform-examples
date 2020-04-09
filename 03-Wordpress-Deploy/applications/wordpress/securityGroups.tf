/*
Load Balance <---> Instance on port 80
*/
resource "aws_security_group_rule" "inbound_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = aws_security_group.SG-LoadBalance.id
  security_group_id = aws_security_group.SG-Wordpress.id
}

/*
ssh access for instances only if is testing environment
*/
resource "aws_security_group_rule" "inbound_ssh" {
  count           = var.environment == "testing"? 1:0
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = [ "0.0.0.0/0" ]
  //source_security_group_id = aws_security_group.SG-LoadBalance.id
  security_group_id = aws_security_group.SG-Wordpress.id
}

/*
EFS ---> Instance on port 2049
*/
resource "aws_security_group_rule" "efs_to_instance" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.SG-EFS.id
  security_group_id        = aws_security_group.SG-Wordpress.id
}
/*
EFS <--- Instance on port 2049
*/
resource "aws_security_group_rule" "instance_to_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.SG-Wordpress.id
  security_group_id        = aws_security_group.SG-EFS.id
}

/*
Segurity Group for instances
*/
resource "aws_security_group" "SG-Wordpress" {
  name        = "application_wordpress_group"
  description = "Allow inbound traffic for Wordpress ${var.environment} environment"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  /*dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
  }*/

  tags = {
    Name         = "application_wordpress_group"
    Environment  = var.environment
    Team         = var.team
    CostCenter   =  var.costCenter
  }

}
/*
Security Group for Load Balance
*/
resource "aws_security_group" "SG-LoadBalance" {
  name        = "loadbalance_wordpress"
  description = "Allow inbound traffic from internet to wordpress load balance"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "loadbalance_wordpress"
    Environment  = var.environment
    Team         = var.team
    CostCenter   = var.costCenter
  }

}

/*
Security Group for Load Balance
*/
resource "aws_security_group" "SG-EFS" {
  name        = "efs_file_share"
  description = "Allow inbound traffic from instances to access EFS nfs mount points"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #     from_port   = 2049
  #     to_port     = 2049
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name         = "efs_file_share"
    Environment  = var.environment
    Team         = var.team
    CostCenter   = var.costCenter
  }

}
