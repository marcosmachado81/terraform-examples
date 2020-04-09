resource "aws_instance" "WordpressInstance" {
  count                       = var.total_instances
  ami                         = var.ami_id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_public_ids[count.index % length(var.subnet_public_ids)]
  vpc_security_group_ids      = [ aws_security_group.SG-Wordpress.id ]
  instance_initiated_shutdown_behavior = "terminate"
  user_data                   =  templatefile("${path.module}/WPDeploy.tmpl", {
                                                DBNAME=var.dbname,
                                                DBUSER=var.dbuser,
                                                DBPASS=var.dbpassword,
                                                DBHOST=var.dbhost,
                                                LOCALE=var.wp_locale,
                                                URL= aws_lb.ALB-Wordpress.dns_name,
                                                ADMUSER=var.wp_user_admin,
                                                ADMPASS=var.wp_user_password,
                                                ADMMAIL=var.wp_user_mail,
                                                BUCKETADDRESS=var.wp_content_bucket_name,
                                                SECRETACCSKEY= aws_iam_access_key.user_s3.secret, //var.s3_secret_access_key,
                                                ACCSKEY= aws_iam_access_key.user_s3.id, //var.s3_access_key,
                                                MOUNTPOINT= var.wordpress_wp_content,
                                                GOOFYSv = "v0.23.1",
                                                EFSID=aws_efs_file_system.wordpress_code.id
                                                })
  tags = {
     Name         = "Wordpress-Deploy-${count.index}"
     Environment  = var.environment
     Team         = var.team
     CostCenter   =  var.costCenter
  }
  iam_instance_profile = aws_iam_instance_profile.ECS-Profile.name

  depends_on = [
                aws_iam_role_policy_attachment.AttachManaged,
                #aws_iam_role_policy_attachment.AttachEC2AccessS3,
                #aws_lb.ALB-Wordpress,
                #aws_efs_mount_target.mount_wp_code,
                #aws_s3_bucket.wp_content_bucket
              ]

}



resource "aws_resourcegroups_group" "WordpressResourceGroup" {
  name = "Wordpress-Resource-Group"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["${var.environment}"]
    }
  ]
}
JSON
}
  tags = {
    Name = "Wordpress-Resource-Group"
    Environment = var.environment
    Team         = var.team
    CostCenter   =  var.costCenter

  }
  depends_on = [aws_instance.WordpressInstance]
}



#S3 Storage to use in wp-content
resource "aws_s3_bucket" "wp_content_bucket" {
  bucket = var.wp_content_bucket_name
  #acl    = "public-read"
  tags = {
    Name        = var.wp_content_bucket_name
    Environment = var.environment
    Team        = var.team
    CostCenter  =  var.costCenter

  }
}

resource "aws_efs_file_system" "wordpress_code" {
  creation_token   = "EFS Wordpress Code Shared Data"
  performance_mode = "generalPurpose"
tags = {
    Name        = "EFS Wordpress Code"
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.costCenter
  }
}

resource "aws_efs_mount_target" "efs" {
  count = length(var.subnet_public_ids)
  file_system_id  = aws_efs_file_system.wordpress_code.id
  subnet_id       = var.subnet_public_ids[count.index]
  security_groups = [ aws_security_group.SG-EFS.id ]
}
/*
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.wp_content_bucket.id

  block_public_acls   = false
  block_public_policy = false
}
*/
/*ETAPAS
https://medium.com/tensult/aws-how-to-mount-s3-bucket-using-iam-role-on-ec2-linux-instance-ad2afd4513ef
Criar bucket com permissão de acesso público
  - wp-content-30493843
  -Cria Role para EC2 acessar S3 (agregar a ROLE para gerenciamento)

*/


#EFS Volume to store wordpress PHP code files
/*
resource "aws_efs_file_system" "wordpress_code" {
  creation_token = "wp-code-efs"

  tags = {
    Name = "WordpressCodeEFS"
    Environment = var.environment
    Team        = var.team
    CostCenter  =  var.costCenter
  }
}

#EFS mount point -> aws_efs_mount_target.ip_address
resource "aws_efs_mount_target" "mount_wp_code" {
  count         = length(var.subnet_public_ids)
  file_system_id = "${aws_efs_file_system.wordpress_code.id}"
  subnet_id      = var.subnet_public_ids[count.index]
  security_groups = aws_security_group.SG-Wordpress.id
}*/
