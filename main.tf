# Specify the AWS Region
provider "aws" {
  region = "ap-south-1"
}


# Creating VPC 
resource "aws_vpc" "vpc_1" {
  cidr_block = "151.25.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

   tags = {
    Name = "MyVPC"
  }
}


# Creating Internet Gateway
resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "InternetGateway1"
  }
}


# Creating 1st Subnet in VPC in 1st availability zone
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "151.25.1.0/24"
  availability_zone       = "ap-south-1a"  # Replace with desired availability zone 
  map_public_ip_on_launch = true          

  tags = {
    Name = "Subnet1"
  }
}


# Creating 2st Subnet in VPC in 2nd availability zone
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "151.25.2.0/24"
  availability_zone       = "ap-south-1b"  # Replace with desired availability zone
  map_public_ip_on_launch = true          

  tags = {
    Name = "Subnet2"
  }
}


# Creating Route Table for 1st Subnet
resource "aws_route_table" "route_table_subnet1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "RouteTableSubnet1"
  }
}


# Creating Route Table for 2nd Subnet
resource "aws_route_table" "route_table_subnet2" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "RouteTableSubnet2"
  }
}


# Associating 1st Route Table with Subnet 1
resource "aws_route_table_association" "subnet_association_subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table_subnet1.id
}


# Associating 2nd Route Table with Subnet 2
resource "aws_route_table_association" "subnet_association_subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table_subnet2.id
}


# IAM Role for CloudWatch Function
resource "aws_iam_role" "cloud_watch_role" {
  name = "cloud_watch_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
    }]
  })
}


# IAM Policy for CloudWatch Function
resource "aws_iam_role_policy" "CloudWatchPolicy" {
  name = "cloud_watch_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
           "logs:CreateLogGroup",
     "logs:CreateLogStream",
     "logs:PutLogEvents",
     "logs:DescribeLogStreams",
     "cloudwatch:PutMetricData",
        ],
        Resource = "*",
        Effect = "Allow"
      }
    ]
  })
}


# Creating IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.cloud_watch_role.id
}


# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security group for EC2 instances in ASG"
  vpc_id      = aws_vpc.vpc_1.id 

  # Ingress rule for SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule - Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
    }]
  })
}


# IAM Policy for Lambda Function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "autoscaling:Describe*",
          "autoscaling:StartInstanceRefresh",
          "sns:Publish"
        ],
        Resource = "*",
        Effect = "Allow"
      }
    ]
  })
}


# Lambda Permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch_to_call_refresh_function" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_refresh_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_refresh.arn
}


#Creating Launch Template for AutoScaling Group 
resource "aws_launch_template" "asg-launch-template-1" {
  name  = "asg-launch-template-1"
  image_id      = var.ami_id # Specifying ID of the ami
  instance_type = var.instance_type   # Specifying Instance Type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Creating Load Balancer
resource "aws_lb" "asg-terraform-lb" {
  name               = "asg-terraform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id] # ID of the created security group for ec2
  subnets            = [aws_subnet.subnet1.id , aws_subnet.subnet2.id] # Subnet IDs of the subnets created
  enable_deletion_protection = false
}


# Creating Target Group for Load Balancer
resource "aws_lb_target_group" "asg-terraform-target-group" {
  name        = "asg-terraform-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_1.id 
}


# Creating Load Balancer Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.asg-terraform-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg-terraform-target-group.arn
  }
}


# Creating Auto Scaling Group
resource "aws_autoscaling_group" "asg-terraform-project" {
  name = "asg-terraform-project"
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.subnet1.id , aws_subnet.subnet2.id]  
  health_check_type       = "EC2"
  force_delete            = true
  wait_for_capacity_timeout = "0"
  

  launch_template {
    id = aws_launch_template.asg-launch-template-1.id
    version = "$Latest"
    }
  target_group_arns    = [aws_lb_target_group.asg-terraform-target-group.arn]
}


# Creating CloudWatch Metric Alarms for scaling based on 'LoadAverage' of the machines 
# 'Scale Up' Alarm 
resource "aws_cloudwatch_metric_alarm" "high_load_alarm" {
  alarm_name          = "high-load"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "LoadAverage"
  namespace           = "MyMetricsasg"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.75"
  alarm_description   = "Alarm when server load is too high"
 

  alarm_actions = [aws_autoscaling_policy.scale_up.arn,
  aws_sns_topic.autoscaling_notifications.arn]
}

# 'Scale Down' Alarm
resource "aws_cloudwatch_metric_alarm" "low_load_alarm" {
  alarm_name          = "low-load"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "LoadAverage"
  namespace           = "MyMetricsasg"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.50"
  alarm_description   = "Alarm when server load is low"
 
  alarm_actions = [aws_autoscaling_policy.scale_down.arn,
  aws_sns_topic.autoscaling_notifications.arn]
}


# Creating Auto Scaling Policies for scaling up and down
# Auto Scaling Policy for 'Scale Up' 
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "30"
  autoscaling_group_name = aws_autoscaling_group.asg-terraform-project.name
}

# Auto Scaling Policy for 'Scale Down'
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "30"
  autoscaling_group_name = aws_autoscaling_group.asg-terraform-project.name
}


# SNS Topic for 'Auto Scaling' Notifications
resource "aws_sns_topic" "autoscaling_notifications" {
  name = "autoscaling-notifications"
}

# SNS Topic Subscription for 'Auto Scaling'
resource "aws_sns_topic_subscription" "email_subscription_autoscaling" {
  topic_arn = aws_sns_topic.autoscaling_notifications.arn
  protocol  = "email"
  endpoint  = "mitalii.vermaa6@gmail.com" # Placing the desired email address
}


# SNS Topic for 'Refreshing Machines' Notifications
resource "aws_sns_topic" "asg_refresh_notification" {
  name = "asg-refresh-notification"
}

# SNS Email Subscription for 'Refreshing Machines' 
resource "aws_sns_topic_subscription" "email_subscription_refreshing" {
  topic_arn = aws_sns_topic.asg_refresh_notification.arn
  protocol  = "email"
  endpoint  = "mitalii.vermaa6@gmail.com"
}


# Lambda Function
resource "aws_lambda_function" "asg_refresh_function" {
  function_name = "asg_refresh_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  s3_bucket     = "streamify-test"
  s3_key        = "LambdaCode.zip"
}


# CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "daily_refresh" {
  name                = "daily-refresh"
  schedule_expression = "cron(0 0 * * ? *)" # Every day at 00:00 UTC
}


# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_refresh.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.asg_refresh_function.arn
}
