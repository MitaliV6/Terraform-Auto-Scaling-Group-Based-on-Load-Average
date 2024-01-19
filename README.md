# Coding-Task-Auto-Scaling-Group-Based-on-Load-Average-Terraform-Code-

This repository contains a Terraform Code which creates Auto Scaling Group based on the 5 minutes Load Average of the machines. 
The maximum instance limit is 5 while the minimum instances that should be availabe are 2. 
When the load average of the machines reaches 75%, scale up process will take place. 
When load average of the machines reaches 50%, scale down process will take place. 
At UTC 12am everyday, all machines will get refreshed (old machines will be removed and new ones will be added).
Email alerts are enabled for all the events (auto scaling and refreshing)


