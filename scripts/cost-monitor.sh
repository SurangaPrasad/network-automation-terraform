#!/bin/bash

# Cost monitoring and reporting script
# This script generates cost reports for the infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_NAME="network-automation"
ENVIRONMENT=${1:-dev}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to get cost for the last 30 days
get_monthly_costs() {
    print_status "Getting monthly costs for $PROJECT_NAME-$ENVIRONMENT..."
    
    START_DATE=$(date -d "30 days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "BlendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --filter '{
            "Tags": {
                "Key": "Project",
                "Values": ["'$PROJECT_NAME'"]
            }
        }' \
        --query 'ResultsByTime[0].Groups[].[Keys[0],Metrics.BlendedCost.Amount]' \
        --output table
}

# Function to get daily costs for the last 7 days
get_daily_costs() {
    print_status "Getting daily costs for the last 7 days..."
    
    START_DATE=$(date -d "7 days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity DAILY \
        --metrics "BlendedCost" \
        --filter '{
            "Tags": {
                "Key": "Project",
                "Values": ["'$PROJECT_NAME'"]
            }
        }' \
        --query 'ResultsByTime[].[TimePeriod.Start,Total.BlendedCost.Amount]' \
        --output table
}

# Function to get cost by service
get_cost_by_service() {
    print_status "Getting cost breakdown by service..."
    
    START_DATE=$(date -d "30 days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "BlendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --filter '{
            "Tags": {
                "Key": "Project",
                "Values": ["'$PROJECT_NAME'"]
            }
        }' \
        --query 'ResultsByTime[0].Groups[] | sort_by(@, &Metrics.BlendedCost.Amount) | reverse(@)[:10]' \
        --output table
}

# Function to get rightsizing recommendations
get_rightsizing_recommendations() {
    print_status "Getting rightsizing recommendations..."
    
    aws ce get-rightsizing-recommendation \
        --service EC2-Instance \
        --filter '{
            "Tags": {
                "Key": "Project",
                "Values": ["'$PROJECT_NAME'"]
            }
        }' \
        --query 'RightsizingRecommendations[?Finding==`OVER_PROVISIONED`].[CurrentInstance.InstanceType,RightsizingType,TargetInstances[0].EstimatedMonthlySavings.Value]' \
        --output table 2>/dev/null || print_warning "Rightsizing recommendations not available"
}

# Function to check for unused resources
check_unused_resources() {
    print_status "Checking for potentially unused resources..."
    
    # Check for unattached EBS volumes
    echo "Unattached EBS volumes:"
    aws ec2 describe-volumes \
        --filters Name=status,Values=available \
        --query 'Volumes[?Tags[?Key==`Project` && Value==`'$PROJECT_NAME'`]].[VolumeId,Size,VolumeType,CreateTime]' \
        --output table
    
    # Check for unused Elastic IPs
    echo -e "\nUnused Elastic IPs:"
    aws ec2 describe-addresses \
        --query 'Addresses[?!InstanceId && Tags[?Key==`Project` && Value==`'$PROJECT_NAME'`]].[PublicIp,AllocationId]' \
        --output table
}

# Function to generate cost alert
generate_cost_alert() {
    print_status "Checking if costs exceed thresholds..."
    
    THRESHOLD=${2:-50} # Default $50 threshold
    
    START_DATE=$(date -d "30 days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    CURRENT_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "BlendedCost" \
        --filter '{
            "Tags": {
                "Key": "Project",
                "Values": ["'$PROJECT_NAME'"]
            }
        }' \
        --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
        --output text)
    
    echo "Current monthly cost: \$$CURRENT_COST"
    echo "Threshold: \$$THRESHOLD"
    
    if (( $(echo "$CURRENT_COST > $THRESHOLD" | bc -l) )); then
        print_warning "ALERT: Monthly costs (\$$CURRENT_COST) exceed threshold (\$$THRESHOLD)!"
    else
        print_success "Costs are within threshold."
    fi
}

# Main execution
case ${1:-""} in
    "monthly")
        get_monthly_costs
        ;;
    "daily")
        get_daily_costs
        ;;
    "service")
        get_cost_by_service
        ;;
    "rightsizing")
        get_rightsizing_recommendations
        ;;
    "unused")
        check_unused_resources
        ;;
    "alert")
        generate_cost_alert $2
        ;;
    "report")
        echo "=== COMPREHENSIVE COST REPORT ==="
        get_monthly_costs
        echo -e "\n"
        get_cost_by_service
        echo -e "\n"
        get_rightsizing_recommendations
        echo -e "\n"
        check_unused_resources
        echo -e "\n"
        generate_cost_alert
        ;;
    *)
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  monthly     - Show monthly costs"
        echo "  daily       - Show daily costs for last 7 days"
        echo "  service     - Show cost breakdown by service"
        echo "  rightsizing - Show rightsizing recommendations"
        echo "  unused      - Check for unused resources"
        echo "  alert       - Check cost alerts (usage: alert [threshold])"
        echo "  report      - Generate comprehensive cost report"
        echo ""
        echo "Examples:"
        echo "  $0 monthly"
        echo "  $0 alert 100"
        echo "  $0 report"
        exit 1
        ;;
esac
