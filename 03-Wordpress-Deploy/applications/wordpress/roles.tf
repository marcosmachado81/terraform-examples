data "aws_iam_policy_document" "trust-policy-ecs-instance" {
  statement {
    sid = "1"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ECS-Profile" {
  name = "Wordpress-Instance-Managed-Profile"
  role = aws_iam_role.WP-Instance-Role.name
}

resource "aws_iam_role" "WP-Instance-Role" {
  name = "RoleEC2AccessS3_SSM"
  assume_role_policy = data.aws_iam_policy_document.trust-policy-ecs-instance.json
}

#Attach SSM support
resource "aws_iam_role_policy_attachment" "AttachManaged" {
  role       = aws_iam_role.WP-Instance-Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
