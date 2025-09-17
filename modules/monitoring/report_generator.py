import json
import boto3
import os
from datetime import datetime, timedelta

def handler(event, context):
    """
    Daily infrastructure report generator
    """
    
    # Initialize AWS clients
    cloudwatch = boto3.client('cloudwatch')
    sns = boto3.client('sns')
    
    # Get environment variables
    project_name = os.environ['PROJECT_NAME']
    environment = os.environ['ENVIRONMENT']
    sns_topic = os.environ['SNS_TOPIC']
    
    # Calculate time ranges
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=1)
    
    try:
        # Collect metrics
        report_data = {
            'alb_metrics': get_alb_metrics(cloudwatch, start_time, end_time),
            'ec2_metrics': get_ec2_metrics(cloudwatch, start_time, end_time),
            'error_count': get_error_count(cloudwatch, start_time, end_time, project_name, environment),
            'health_status': get_health_status(cloudwatch, start_time, end_time)
        }
        
        # Generate report
        report = generate_report(project_name, environment, report_data, start_time, end_time)
        
        # Send report via SNS
        send_report(sns, sns_topic, report, project_name, environment)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Report generated and sent successfully')
        }
        
    except Exception as e:
        print(f"Error generating report: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def get_alb_metrics(cloudwatch, start_time, end_time):
    """Get ALB metrics"""
    try:
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='RequestCount',
            Dimensions=[],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Sum']
        )
        
        total_requests = sum([point['Sum'] for point in response['Datapoints']])
        
        return {
            'total_requests': total_requests,
            'avg_requests_per_hour': total_requests / 24 if total_requests > 0 else 0
        }
    except Exception as e:
        print(f"Error getting ALB metrics: {str(e)}")
        return {'total_requests': 0, 'avg_requests_per_hour': 0}

def get_ec2_metrics(cloudwatch, start_time, end_time):
    """Get EC2 metrics"""
    try:
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Average', 'Maximum']
        )
        
        if response['Datapoints']:
            avg_cpu = sum([point['Average'] for point in response['Datapoints']]) / len(response['Datapoints'])
            max_cpu = max([point['Maximum'] for point in response['Datapoints']])
        else:
            avg_cpu = 0
            max_cpu = 0
        
        return {
            'avg_cpu_utilization': round(avg_cpu, 2),
            'max_cpu_utilization': round(max_cpu, 2)
        }
    except Exception as e:
        print(f"Error getting EC2 metrics: {str(e)}")
        return {'avg_cpu_utilization': 0, 'max_cpu_utilization': 0}

def get_error_count(cloudwatch, start_time, end_time, project_name, environment):
    """Get application error count"""
    try:
        response = cloudwatch.get_metric_statistics(
            Namespace=f'NetworkAutomation/{environment}',
            MetricName='ErrorCount',
            Dimensions=[],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Sum']
        )
        
        total_errors = sum([point['Sum'] for point in response['Datapoints']])
        return int(total_errors)
    except Exception as e:
        print(f"Error getting error count: {str(e)}")
        return 0

def get_health_status(cloudwatch, start_time, end_time):
    """Get overall health status"""
    try:
        # Check for any alarm states
        response = cloudwatch.describe_alarms(
            StateValue='ALARM'
        )
        
        active_alarms = len(response['MetricAlarms'])
        
        return {
            'active_alarms': active_alarms,
            'status': 'HEALTHY' if active_alarms == 0 else 'DEGRADED'
        }
    except Exception as e:
        print(f"Error getting health status: {str(e)}")
        return {'active_alarms': 0, 'status': 'UNKNOWN'}

def generate_report(project_name, environment, data, start_time, end_time):
    """Generate formatted report"""
    
    report = f"""
🌐 Network Automation Infrastructure Report
Project: {project_name} | Environment: {environment}
Report Period: {start_time.strftime('%Y-%m-%d %H:%M')} UTC to {end_time.strftime('%Y-%m-%d %H:%M')} UTC

📊 APPLICATION LOAD BALANCER
• Total Requests: {data['alb_metrics']['total_requests']:,}
• Average Requests/Hour: {data['alb_metrics']['avg_requests_per_hour']:.0f}

🖥️ EC2 INSTANCES
• Average CPU Utilization: {data['ec2_metrics']['avg_cpu_utilization']}%
• Peak CPU Utilization: {data['ec2_metrics']['max_cpu_utilization']}%

⚠️ ERROR TRACKING
• Total Application Errors: {data['error_count']}

🔍 HEALTH STATUS
• Overall Status: {data['health_status']['status']}
• Active Alarms: {data['health_status']['active_alarms']}

💡 RECOMMENDATIONS
"""

    # Add recommendations based on metrics
    recommendations = []
    
    if data['ec2_metrics']['avg_cpu_utilization'] > 70:
        recommendations.append("• Consider scaling up EC2 instances due to high CPU utilization")
    
    if data['error_count'] > 10:
        recommendations.append("• Investigate application errors - count is above normal threshold")
    
    if data['health_status']['active_alarms'] > 0:
        recommendations.append(f"• Review and resolve {data['health_status']['active_alarms']} active alarm(s)")
    
    if data['alb_metrics']['total_requests'] == 0:
        recommendations.append("• No traffic detected - verify application accessibility")
    
    if not recommendations:
        recommendations.append("• No issues detected - system operating normally")
    
    report += '\n'.join(recommendations)
    
    report += f"""

📈 DASHBOARD
View real-time metrics: https://console.aws.amazon.com/cloudwatch/home#dashboards:name={project_name}-{environment}-dashboard

Generated at: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC
"""
    
    return report

def send_report(sns, topic_arn, report, project_name, environment):
    """Send report via SNS"""
    
    subject = f"Daily Report: {project_name} {environment.upper()} Infrastructure"
    
    sns.publish(
        TopicArn=topic_arn,
        Subject=subject,
        Message=report
    )
