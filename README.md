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

Before plan and apply:
1. You must create variables in Systems Manager (SM Parameters) for database wordpress users (username and password). You need create based on your environment. For example, If I have testing workspace I create four variables:  
/wordpress/**testing**/db_user    type string  
/wordpress/**testing**/db_pass    type securestring  
/wordpress/**testing**/wp_user    type string  
/wordpress/**testing**/wp_pass    type securestring  
