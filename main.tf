# Creating Auto Scaling Group
resource "aws_autoscaling_group" "asg-terraform-project" {
  name = "asg-terraform-project"
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier  = ["subnet-0dd68c5ed1ba79cae", "subnet-008e7570bae13c08f"]  # Placing the subnet IDs
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