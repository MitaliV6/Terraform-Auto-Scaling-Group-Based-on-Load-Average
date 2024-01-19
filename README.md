# Coding-Task-Auto-Scaling-Group-Based-on-Load-Average-Terraform-Code-

This repository contains a Terraform Code which creates Auto Scaling Group based on the 5 minutes Load Average of the machines. 
The maximum instance limit is 5 while the minimum instances that should be availabe are 2. 
When the load average of the machines reaches 75%, scale up process will take place. 
When load average of the machines reaches 50%, scale down process will take place. 
At UTC 12am everyday, all machines will get refreshed (old machines will be removed and new ones will be added).
Email alerts are enabled for all the events (auto scaling and refreshing)

PREREQUISITES :
1. Access Key and Secret Access Key of AWS. 
2. Default VPC & Subnet IDs. 

PREREQUISITES in AMI : 
1. AWS CLI
2. Cron to send Load Average of machine to the CloudWatch, with the following command :
* * * * * /usr/bin/aws cloudwatch put-metric-data --region ap-south-1 --metric-name LoadAverage --namespace MyMetricsasg --value $(uptime | awk -F'[a-z]:' '{ print $2 }' | cut -d, -f2) --unit None >/dev/null 2>&1

Lambda Function required for Refreshing Machines at UTC 12AM Everyday is wriiten in Python and present in this repository only, by the name index.py.



