# terraform-examples
examples for terraform 0.12

# 01-Static-WebSite:
Simple deploy of a static website inside a public subnet and configured to be managed by AWS System Manager. The deploy uses Document file.

# 02-LoadBalance-Static-Website:
add a public Application Load Balance to the example

# 03-Wordpress-Deploy
More complex environment using locals, workspaces and modules.
 - Create wordpress installation environment.
 - Define loadBalance
 - Creates autoScale policy
 - Use S3 bucket for files in wp-content/uploads
 - Use EFS for wordpress code files
 - Remote terraform state

To access S3 bucket from instance needs create a programmatic access user with permission to access S3 bucket. After creates 2 variable s3_access_key and s3_secret_access_key inside variables.tf or create a file s3_access_credential.tf
