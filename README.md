#Terraform Auto Scaling Group based on Load Average

This repository contains Terraform code for automating the creation of an Auto Scaling Group (ASG) in AWS, leveraging load average metrics for dynamic scaling and instance refreshes. The ASG ensures optimal resource allocation based on the 5-minute load average of the instances, facilitating efficient scaling up or down as needed.

Features:

Dynamic Scaling: The ASG automatically adjusts the number of instances based on load average metrics. When the load average reaches 75%, the ASG scales up to meet increased demand. Conversely, when the load average drops to 50%, the ASG scales down to optimize resource utilization.
Instance Refresh: All instances within the ASG are refreshed at UTC 12am every day to maintain system health and performance. This process involves removing old instances and provisioning new ones.
Email Alerts: Email alerts are configured to notify administrators of scaling events and instance refreshes, ensuring timely awareness of system changes.
Prerequisites:

Before using this Terraform configuration, ensure the following prerequisites are met:

AWS Access Key and Secret Access Key with appropriate permissions.
AWS CLI installed on instances within the ASG.
Lambda function for refreshing instances at UTC 12am.
Cron job set up on instances to send load average metrics to CloudWatch.
AMI Requirements:

The AMI used for instances within the ASG should include the following:

AWS CLI installed.
Cron job configured to send load average metrics to CloudWatch.
Usage:

To use this Terraform configuration:

Clone this repository to your local machine.
Update the terraform.tfvars file with your AWS credentials and any other configuration variables.
Run terraform init to initialize the Terraform project.
Run terraform apply to create the Auto Scaling Group and associated resources in AWS.
Lambda Function:

The repository includes a Python-based Lambda function (index.py) for refreshing instances at UTC 12am. Ensure the Lambda function is deployed and configured appropriately for use with the ASG.
