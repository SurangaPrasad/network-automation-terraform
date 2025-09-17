#!/bin/bash

# Update system
yum update -y

# Install necessary packages
yum install -y httpd amazon-cloudwatch-agent

# Install Docker for containerized applications
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Node.js (for modern web applications)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Create a simple web application
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Network Automation Platform</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .status { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🌐 Network Automation Platform</h1>
        <div class="info">
            <h2>Infrastructure Status</h2>
            <p class="status">✅ Load Balancer: Active</p>
            <p class="status">✅ Auto Scaling: Enabled</p>
            <p class="status">✅ Database: Connected</p>
            <p class="status">✅ Monitoring: Active</p>
        </div>
        <div class="info">
            <h2>Environment Details</h2>
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
        </div>
        <div class="info">
            <h2>Network Automation Features</h2>
            <ul>
                <li>Automated Infrastructure Provisioning</li>
                <li>Load Balancing & High Availability</li>
                <li>Auto Scaling Based on Demand</li>
                <li>Database Clustering & Backup</li>
                <li>DNS Management & SSL Termination</li>
                <li>WAF Protection & Security Groups</li>
                <li>CloudWatch Monitoring & Alerting</li>
            </ul>
        </div>
    </div>
    
    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data);
        
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data);
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
    <h1>OK</h1>
    <p>Service is healthy</p>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Configure Apache
systemctl start httpd
systemctl enable httpd

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "NetworkAutomation/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/${project_name}-${environment}",
                        "log_stream_name": "{instance_id}/apache/access.log"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/${project_name}-${environment}",
                        "log_stream_name": "{instance_id}/apache/error.log"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create a simple API endpoint for network automation
mkdir -p /opt/network-automation
cat > /opt/network-automation/app.js << 'EOF'
const express = require('express');
const app = express();
const port = 8080;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'network-automation-api'
    });
});

// Network status endpoint
app.get('/api/network/status', (req, res) => {
    res.json({
        network: {
            vpc: 'active',
            subnets: 'configured',
            routing: 'operational',
            security_groups: 'applied'
        },
        load_balancer: {
            status: 'healthy',
            targets: 'in_service'
        },
        database: {
            connection: 'established',
            replication: 'active'
        }
    });
});

// Infrastructure metrics endpoint
app.get('/api/metrics', (req, res) => {
    res.json({
        cpu_utilization: Math.random() * 100,
        memory_usage: Math.random() * 100,
        network_in: Math.random() * 1000000,
        network_out: Math.random() * 1000000,
        timestamp: new Date().toISOString()
    });
});

app.listen(port, () => {
    console.log(`Network automation API listening at http://localhost:${port}`);
});
EOF

# Install and start the Node.js application
cd /opt/network-automation
npm init -y
npm install express
node app.js &

# Configure log rotation
cat > /etc/logrotate.d/network-automation << 'EOF'
/var/log/network-automation/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 0644 root root
}
EOF

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
