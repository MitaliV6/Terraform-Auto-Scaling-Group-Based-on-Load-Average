import boto3
import json

def handler(event, context):
    auto_scaling_client = boto3.client('autoscaling', region_name='ap-south-1')
    sns_client = boto3.client('sns', region_name='ap-south-1')

    sns_topic_arn = 'arn:aws:sns:ap-south-1:{your-account-id}:asg-refresh-notification'  # Replace with your SNS Topic ARN  # Replace with your SNS Topic ARN

    try:
        response = auto_scaling_client.start_instance_refresh(
            AutoScalingGroupName='asg-terraform-project',
            Strategy='Rolling',
            Preferences={
                'MinHealthyPercentage': 100,
                'InstanceWarmup': 30
            }
        )

        # Send a notification to SNS topic
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message='Instance refresh started successfully.',
            Subject='Instance Refresh Notification'
        )

        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps("Error starting instance refresh")
        }
