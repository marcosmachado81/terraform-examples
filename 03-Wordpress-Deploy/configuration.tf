provider "aws" {
  region = local.region
  shared_credentials_file = "../.aws/credentials"
  profile="terraform"

}

terraform {
  backend "s3" {
    bucket = "tf-remote-state-04938473"
    key = "terraform-wordpress/03_static_website_terraform.tfstate"
    region = "eu-west-3"
    shared_credentials_file = "../.aws/credentials"
    profile="terraform"
  }
}
