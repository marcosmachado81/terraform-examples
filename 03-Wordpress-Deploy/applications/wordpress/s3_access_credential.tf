resource "aws_iam_user" "user_s3" {
  name = "s3access"
  #path = "/system/"
}
resource "aws_iam_access_key" "user_s3" {
  user = aws_iam_user.user_s3.name
}

resource "aws_iam_user_policy_attachment" "user_s3" {
  user       = aws_iam_user.user_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
