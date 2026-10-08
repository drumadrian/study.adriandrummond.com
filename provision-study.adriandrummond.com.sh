#!/bin/bash
# Description: AWS Infrastructure Provisioning Script for study.adriandrummond.com

set -e

if [ -f ".env" ]; then
  source .env
else
  echo "Error: .env file not found."
  exit 1
fi

export AWS_REGION="${AWS_REGION:-us-east-1}"

mkdir -p logs
LOG_FILE="logs/provision-aws_$(date +%F_%T).log"

{
function step_start() {
    echo -e "🟨 $1..."
}

function step_done() {
    echo -e "✅ $1 completed."
}

DEPLOYMENT_NAME="study-server-$(date +%s)"
PROJECT_TAG="StudyServer"
COMMON_TAGS="{Key=Project,Value=$PROJECT_TAG},{Key=DeploymentName,Value=$DEPLOYMENT_NAME},{Key=Name,Value=$DEPLOYMENT_NAME}"
TAG_SPEC="ResourceType=instance,Tags=[$COMMON_TAGS]"
VPC_TAG_SPEC="ResourceType=vpc,Tags=[$COMMON_TAGS]"
SUBNET_TAG_SPEC="ResourceType=subnet,Tags=[$COMMON_TAGS]"
IGW_TAG_SPEC="ResourceType=internet-gateway,Tags=[$COMMON_TAGS]"
RT_TAG_SPEC="ResourceType=route-table,Tags=[$COMMON_TAGS]"
SG_TAG_SPEC="ResourceType=security-group,Tags=[$COMMON_TAGS]"

# ============================================================
# 1) VPC + Networking
# ============================================================
step_start "Creating VPC"
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "$VPC_TAG_SPEC" --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}"
step_done "Creating VPC"

step_start "Creating Subnet"
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --tag-specifications "$SUBNET_TAG_SPEC" --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch
step_done "Creating Subnet"

step_start "Creating Internet Gateway"
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications "$IGW_TAG_SPEC" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
step_done "Creating Internet Gateway"

step_start "Configuring Route Table"
RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "$RT_TAG_SPEC" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_ID" --route-table-id "$RT_ID"
step_done "Configuring Route Table"

# ============================================================
# 2) Security Group
# ============================================================
step_start "Creating Security Group"
SG_ID=$(aws ec2 create-security-group --group-name "StudyServer-SG-$DEPLOYMENT_NAME" --description "SG for study.adriandrummond.com" --vpc-id "$VPC_ID" --tag-specifications "$SG_TAG_SPEC" --query 'GroupId' --output text)

echo "Fetching Developer Public IP..."
DEV_IP=$(curl -s --max-time 10 ifconfig.me)
if [ -z "$DEV_IP" ]; then
    echo "⚠️  Failed to retrieve public IP. Using 0.0.0.0/0 as fallback."
    DEV_IP="0.0.0.0/0"
else
    DEV_IP="${DEV_IP}/32"
fi

# Allow all necessary traffic from Developer IP
echo "Authorizing all traffic for $DEV_IP..."
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol all --port all --cidr "$DEV_IP"

step_done "Creating Security Group"

# ============================================================
# 3) SSH Key Pair
# ============================================================
step_start "Setting up SSH Key"
mkdir -p certificates
KEY_NAME="study-server-ec2-key"
KEY_PATH="certificates/${KEY_NAME}.pem"

if [ -f "$KEY_PATH" ]; then
    echo "Found existing SSH key at $KEY_PATH."
else
    echo "Generating new SSH key pair..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_PATH"
    chmod 400 "$KEY_PATH"
    echo "SSH Key saved to $KEY_PATH locally."
fi
step_done "Setting up SSH Key"

# ============================================================
# 4) Launch EC2 Instance
# ============================================================
AMI_ID="${AMI:-ami-0c55b159cbfafe1f0}"

step_start "Launching EC2 Instance"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type m5.xlarge \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":500,"VolumeType":"gp3"}}]' \
    --tag-specifications "$TAG_SPEC" \
    --query 'Instances[0].InstanceId' \
    --output text)
step_done "Launching EC2 Instance"

step_start "Waiting for instance to be running"
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

echo "Allocating Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
ELASTIC_IP=$(aws ec2 describe-addresses --allocation-ids "$ALLOCATION_ID" --query 'Addresses[0].PublicIp' --output text)

echo "Associating Elastic IP ($ELASTIC_IP) with instance $INSTANCE_ID..."
aws ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOCATION_ID"

PUBLIC_IP=$ELASTIC_IP
step_done "Waiting for instance to be running"

# ============================================================
# 5) Save State to .env
# ============================================================
step_start "Saving deployment state to .env"

# Remove old EC2 Deployment information from .env and append new
sed -i.bak '/^VPC_ID=/d' .env
sed -i.bak '/^SUBNET_ID=/d' .env
sed -i.bak '/^SG_ID=/d' .env
sed -i.bak '/^INSTANCE_ID=/d' .env
sed -i.bak '/^PUBLIC_IP=/d' .env
sed -i.bak '/^KEY_PATH=/d' .env
rm -f .env.bak

cat <<EOF >> .env
VPC_ID="$VPC_ID"
SUBNET_ID="$SUBNET_ID"
SG_ID="$SG_ID"
INSTANCE_ID="$INSTANCE_ID"
PUBLIC_IP="$PUBLIC_IP"
KEY_PATH="$KEY_PATH"
EOF

step_done "Saving deployment state to .env"

# ============================================================
# 6) Copy and Run Installer
# ============================================================
step_start "Running installer on EC2 instance"

echo "Waiting for SSH to be available on $PUBLIC_IP..."
max_retries=30
count=0
while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEY_PATH" ec2-user@$PUBLIC_IP "echo SSH is ready" >/dev/null 2>&1; do
  sleep 5
  count=$((count+1))
  if [ $count -ge $max_retries ]; then
    echo "Timeout waiting for SSH."
    exit 1
  fi
done

echo "Copying configuration and script to server..."
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" .env ec2-user@$PUBLIC_IP:/home/ec2-user/.env
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" install-study-server.sh ec2-user@$PUBLIC_IP:/home/ec2-user/install-study-server.sh
scp -r -o StrictHostKeyChecking=no -i "$KEY_PATH" app ec2-user@$PUBLIC_IP:/home/ec2-user/app
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" generate-ssl.sh ec2-user@$PUBLIC_IP:/home/ec2-user/generate-ssl.sh
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" provision-cognito.sh ec2-user@$PUBLIC_IP:/home/ec2-user/provision-cognito.sh

echo "Executing installer..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ec2-user@$PUBLIC_IP "chmod +x /home/ec2-user/install-study-server.sh && sudo /home/ec2-user/install-study-server.sh"

step_done "Running installer on EC2 instance"

echo "================================================================"
echo "✅ Deployment Complete!"
echo "  Public IP: $PUBLIC_IP"
echo "  SSH Key: $KEY_PATH"
echo "================================================================"

} 2>&1 | tee -a "$LOG_FILE"