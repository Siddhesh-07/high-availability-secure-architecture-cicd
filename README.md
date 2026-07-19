# High-Availability Secure Architecture CI/CD Platform (HASA)

A production-grade CI/CD pipeline demonstrating automated infrastructure provisioning, containerization, and zero-downtime application deployments on AWS. This capstone project combines Terraform, Docker, GitHub Actions, and AWS native services to create a scalable, secure, and fully automated deployment system.

---

## 🎯 Project Overview

HASA is a complete DevOps platform that showcases real-world industry practices:

- **Infrastructure as Code:** AWS resources defined and managed entirely through Terraform
- **Containerization:** Docker containers deployed to private EC2 instances
- **Automated CI/CD:** GitHub Actions pipelines for infrastructure and application updates
- **Zero-Downtime Deployments:** AWS Instance Refresh for rolling updates without service interruption
- **High Availability:** Multi-AZ setup with load balancing and auto-scaling
- **Security:** Private subnets, IAM roles, Systems Manager for secure access

### Why This Matters

This architecture mirrors how Netflix, Uber, and Stripe deploy code. A single `git push` automatically builds, tests, and rolls out your code to production without downtime.

---

## 🏗️ Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Internet (0.0.0.0/0)                        │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Internet Gateway   │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┴──────────────────────┐
        │                                             │
   ┌────▼────────────────────┐            ┌──────────▼──────────┐
   │   Public Subnet (1a)    │            │  Public Subnet (1b) │
   │   10.0.1.0/24           │            │   10.0.4.0/24       │
   ├─────────────────────────┤            ├─────────────────────┤
   │ ┌─────────────────────┐ │            │ ┌─────────────────┐ │
   │ │  Load Balancer      │ │            │ │  NAT Gateway    │ │
   │ │  (Port 80 → 5000)   │ │            │ │  (Outbound)     │ │
   │ └─────────────────────┘ │            │ └─────────────────┘ │
   └────┬────────────────────┘            └─────────┬───────────┘
        │                                            │
        │                  ┌─────────────────────────┘
        │                  │
   ┌────▼──────────────────▼──────────┐  ┌────────────────────────┐
   │   Private Subnet (2a)            │  │   Private Subnet (2b)  │
   │   10.0.2.0/24 (us-east-1a)       │  │   10.0.3.0/24 (1b)     │
   ├──────────────────────────────────┤  ├────────────────────────┤
   │ ┌────────────────────────────┐   │  │ ┌──────────────────┐   │
   │ │   EC2 Instance (t3.micro)  │   │  │ │  EC2 Instance    │   │
   │ │   - Docker running         │   │  │ │  - Docker running│   │
   │ │   - Port 5000 listening    │   │  │ │  - Port 5000 ✅  │   │
   │ │   - Flask app deployed     │   │  │ │  - Flask app ✅  │   │
   │ │   - SSM Agent for updates  │   │  │ │  - SSM Agent ✅  │   │
   │ └────────────────────────────┘   │  │ └──────────────────┘   │
   │                                  │  │                        │
   │   Health Check: ✅ HEALTHY       │  │   Health Check: ✅ OK │
   └──────────────────────────────────┘  └────────────────────────┘
        │                                            │
        └──────────────────┬─────────────────────────┘
                           │
                  ┌────────▼────────┐
                  │  Target Group   │
                  │  (Port 5000)    │
                  └────────────────┘
                           │
                  ┌────────▼────────┐
                  │   User Browser  │
                  └─────────────────┘
                  
────────────────────────────────────────────────────────────

Separate Control Layer (Not on Public Internet):

┌──────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline               │
├──────────────────────────────────────────────────────────┤
│  1. Code Push → 2. Build Docker → 3. Push to ECR         │
│  4. Update Launch Template → 5. Trigger Instance Refresh │
│  6. Monitor Rolling Update (Zero Downtime) ✅            │
└──────────────────────────────────────────────────────────┘

AWS Services:

┌────────────────┐  ┌──────────────┐  ┌────────────────┐
│      ECR       │  │  S3 Bucket   │  │   DynamoDB     │
│ (Docker Images)│  │ (TF State)   │  │ (State Locks)  │
└────────────────┘  └──────────────┘  └────────────────┘
```

---

## 🔄 Dual Pipeline CI/CD Architecture (THE GAME CHANGER)

### The Two Pipelines

HASA uses **two independent, specialized GitHub Actions workflows** that work in harmony:

```
                           GitHub Repository
                           ├─ terraform/** files
                           ├─ app/** files
                           └─ Dockerfile
                                 │
                ┌────────────────┬┴──────────────┐
                │                │               │
           (Terraform)      (App Code)      (Docker)
           files change    OR Dockerfile     change
                │           changed         detected
                │                │               │
                ▼                ▼               ▼
          ┌──────────────┐  ┌──────────────────────┐
          │  infra.yml   │  │    deploy.yml        │
          │  TRIGGERED   │  │    TRIGGERED         │
          └──────┬───────┘  └──────────┬───────────┘
                 │                     │
    ┌────────────▼─────────────────┐ ┌──▼──────────────────────────┐
    │ INFRASTRUCTURE PIPELINE      │ │ APPLICATION PIPELINE        │
    │ ════════════════════════     │ │ ═════════════════════════   │
    │                              │ │                             │
    │ File: .github/workflows/     │ │ File: .github/workflows/    │
    │       infra.yml              │ │       deploy.yml            │
    │                              │ │                             │
    │ Trigger: terraform/** files  │ │ Trigger: app/** OR          │
    │          changed             │ │          Dockerfile         │
    │                              │ │                             │
    │ Steps:                       │ │ Steps:                      │
    │ 1. Checkout code            │ │ 1. Checkout code             │
    │ 2. Setup Terraform          │ │ 2. AWS Credentials           │
    │ 3. Initialize backend (S3)  │ │ 3. Login to ECR              │
    │ 4. Format check             │ │ 4. Build Docker image        │
    │ 5. Validate syntax          │ │ 5. Push to ECR               │
    │ 6. Plan changes             │ │ 6. Update Launch Template    │
    │ 7. Apply to AWS             │ │ 7. Trigger ASG refresh       │
    │                              │ │ 8. Monitor deployment       │
    │ What Gets Updated:          │ │                              │
    │ ✓ VPC & Subnets            │ │ What Gets Updated:            │
    │ ✓ ALB & Target Groups      │ │ ✓ Docker image               │
    │ ✓ ASG & Launch Template    │ │ ✓ Launch Template version    │
    │ ✓ Security Groups          │ │ ✓ Running containers         │
    │ ✓ IAM Roles & Policies     │ │                              │
    │ ✓ ECR Repository           │ │ Result: Application code     │
    │ ✓ S3 & DynamoDB            │ │ deployed across all EC2s     │
    │                              │ │ ZERO DOWNTIME: ✅          │
    │ Duration: ~2-3 minutes      │ │ Duration: ~10-15 minutes    │
    │ Frequency: Rare (only       │ │ Frequency: Every code push  │
    │ when infra needs changing)  │ │                             │
    └────────────┬────────────────┘ └──────────┬──────────────────┘
                 │                             │
                 │     Both pipelines may      │
                 │     trigger ASG Instance    │
                 │     Refresh if changes      │
                 │     affect Launch Template  │
                 │                             │
                 └──────────┬──────────────────┘
                           │
                 ┌─────────▼──────────┐
                 │   ASG Instance     │
                 │   Refresh Logic    │
                 │   ═══════════════  │
                 │                    │
                 │ Rolling Update:    │
                 │ • Keep 50% healthy │
                 │ • Launch new inst  │
                 │ • Wait for health  │
                 │ • Terminate old    │
                 │ • Repeat           │
                 │                    │
                 │ Zero Downtime: ✅  │
                 └─────────┬──────────┘
                           │
            ┌──────────────▼──────────────┐
            │ AWS Fully Updated + App     │
            │ Running Latest Code Version │
            │ Zero Service Interruption ✅│
            └─────────────────────────────┘
```

### Why This Dual Pipeline Approach is Brilliant

| Aspect | Infrastructure Pipeline (infra.yml) | Application Pipeline (deploy.yml) |
|--------|-----|-----|
| **Triggers On** | `terraform/**` file changes | `app/**` or `Dockerfile` changes |
| **What It Does** | Provisions/updates AWS resources | Builds and deploys application code |
| **Duration** | 2-3 minutes | 10-15 minutes (includes warmup) |
| **Frequency** | Rare (infrastructure changes infrequently) | Often (every code push) |
| **Scope** | VPC, ALB, ASG, IAM, Security, State | Docker image, containers, versions |
| **Failure Impact** | Infrastructure issues | Application issues |
| **Downtime Risk** | Possible | Zero (rolling updates) |

### Real-World Example

**Scenario 1: You need to add a new security group rule**

```bash
# Edit terraform/security_groups.tf
# Add new ingress rule for port 8080

git add terraform/security_groups.tf
git commit -m "add port 8080 security rule"
git push origin main

# What happens:
# ✅ infra.yml TRIGGERS (detected terraform/** change)
# ❌ deploy.yml does NOT trigger (no app/** change)
# 
# Result: Security group updated in AWS, no app redeployment
```

**Scenario 2: You push a bug fix**

```bash
# Edit app/app.py
# Fix a bug in the /health endpoint

git add app/app.py
git commit -m "fix health check endpoint"
git push origin main

# What happens:
# ❌ infra.yml does NOT trigger (no terraform/** change)
# ✅ deploy.yml TRIGGERS (detected app/** change)
#
# Result: 
# - Docker image rebuilt with fix
# - Pushed to ECR
# - Launch Template updated
# - ASG rolls out new version (zero downtime)
# - Infrastructure unchanged
```

### The Problem This Solves

**Without separation (common mistake):**
- Every code change triggers full Terraform apply
- Infrastructure gets recreated unnecessarily
- Deployments take 30+ minutes
- Huge risk if infrastructure change breaks something
- Developers scared to deploy frequently

**With HASA's dual pipeline approach:**
- ✅ Infrastructure updates only when needed
- ✅ Application deployments are fast (10-15 mins)
- ✅ Clear separation of concerns
- ✅ Different SLAs (rare infra changes, frequent app changes)
- ✅ Easier to debug ("which pipeline failed?")
- ✅ Better disaster recovery (can recreate infrastructure independently)

---

## 🚀 Getting Started

### Prerequisites

- AWS Account with permissions to create VPC, EC2, ALB, ECR, S3, DynamoDB
- Terraform >= 1.0
- Docker (for local testing)
- GitHub Account
- AWS CLI v2
- Git

### Setup Steps

#### 1. Clone Repository

```bash
git clone https://github.com/YOUR-USERNAME/high-availability-secure-architecture-cicd.git
cd high-availability-secure-architecture-cicd
```

#### 2. Configure AWS Credentials

```bash
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Region: us-east-1
# Output format: json
```

#### 3. Add GitHub Secrets

Go to **GitHub Repository → Settings → Secrets and variables → Actions**

Add:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### 4. Initialize and Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will:
- Create VPC with multi-AZ setup
- Launch ALB and ASG
- Set up ECR repository
- Create S3 bucket and DynamoDB table for state management
- Configure IAM roles for EC2 instances

**Output:** You'll see the ALB DNS name. Save it.

#### 5. Deploy Application

Push code to trigger the pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
- Build Docker image
- Push to ECR
- Update Launch Template
- Perform rolling update (0 downtime)

#### 6. Verify Deployment

Visit your ALB URL:
```
http://<ALB-DNS-NAME>
```

You should see:
```json
{
  "status": "Healthy",
  "message": "Welcome to HASA Production App!",
  "version": "1.0.0",
  "hostname": "ip-10-0-2-45",
  "environment": "production"
}
```

Refresh the page multiple times. The `hostname` should alternate between different instances (proof of load balancing).

---

## 📁 Project Structure

```
high-availability-secure-architecture-cicd/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # VPC, subnets, networking
│   ├── alb.tf                    # Load balancer & target groups
│   ├── asg.tf                    # Auto Scaling Group with Instance Refresh
│   ├── iam.tf                    # IAM roles & policies
│   ├── launch_template.tf        # EC2 blueprint with Docker setup
│   ├── security_groups.tf        # Firewall rules
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   └── backend.tf                # S3 state configuration
│
├── .github/workflows/            # CI/CD Pipelines (DUAL PIPELINE)
│   ├── infra.yml                 # 🔧 Infrastructure Pipeline
│   │                             #    Triggers: terraform/** changes
│   │                             #    Does: Terraform init → validate → plan → apply
│   │                             #    Duration: 2-3 mins
│   │
│   └── deploy.yml                # 🚀 Application Pipeline
│                                 #    Triggers: app/** OR Dockerfile changes
│                                 #    Does: Build → Push ECR → Update LT → Refresh ASG
│                                 #    Duration: 10-15 mins (zero downtime)
│
├── app/                          # Flask Application
│   └── app.py                    # Simple DevOps-friendly API
│
├── Dockerfile                    # Container blueprint
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## 🔧 Infrastructure Pipeline (infra.yml)

```yaml
name: "Phase 1: Infrastructure Deployment"

on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'  # Only trigger on terraform/ changes

env:
  AWS_REGION: us-east-1

jobs:
  terraform:
    name: "Automate Terraform Lifecycle"
    runs-on: ubuntu-latest
    
    defaults:
      run:
        working-directory: ./terraform

    steps:
      - name: Checkout Repository Code
        uses: actions/checkout@v4

      - name: Configure AWS Administrative Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup HashiCorp Terraform CLI
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.5.0"

      - name: Initialize Terraform Backend
        run: terraform init

      - name: Check Code Formatting
        run: terraform fmt -check

      - name: Validate Configuration Syntax
        run: terraform validate

      - name: Generate Infrastructure Execution Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
      
      - name: Execute Terraform Apply
        run: terraform apply -auto-approve tfplan
```

**What This Pipeline Does:**
1. Detects changes to any `terraform/**` files
2. Initializes Terraform with S3 backend
3. Validates syntax and formatting
4. Plans changes (shows what will be created/modified/destroyed)
5. Applies changes to AWS
6. If Launch Template changed, ASG automatically triggers Instance Refresh

---

## 🚀 Application Pipeline (deploy.yml)

See full deploy.yml code in the [Dual Pipeline Architecture section above](#-dual-pipeline-cicd-architecture-the-game-changer)

---

## 🔄 How It Works

### Deployment Flow

```
Developer commits code
        │
        ▼
GitHub detects change (app/** or Dockerfile)
        │
        ▼
GitHub Actions triggers deploy.yml
        │
        ├─ Checkout code
        ├─ Configure AWS credentials
        ├─ Login to ECR
        │
        ├─ Build Docker image
        │  └─ Tag: git_commit_sha + latest
        │
        ├─ Push image to ECR
        │  └─ Private AWS Docker registry
        │
        ├─ Update Launch Template
        │  ├─ Get current LT version
        │  ├─ Create new version with updated UserData
        │  └─ UserData now pulls new Docker image
        │
        ├─ Trigger Instance Refresh
        │  └─ Starts rolling update process
        │
        └─ Monitor Instance Refresh
           ├─ Launches new instance with new LT
           ├─ Waits for health checks to pass
           ├─ Terminates old instance
           ├─ Repeats for remaining instances
           └─ Exit when all instances updated (Successful)

Result: 
  ✅ Zero downtime
  ✅ All instances running new code
  ✅ Load balancer never had 0 healthy targets
  ✅ Automatic rollback if health checks fail
```

### Infrastructure Pipeline

Changes to `terraform/**` files trigger automatic Terraform apply:

```bash
git add terraform/main.tf
git commit -m "Update VPC CIDR"
git push origin main

# Automatically:
# 1. Terraform validates
# 2. Terraform plans changes
# 3. Terraform applies changes
# 4. ASG Instance Refresh if Launch Template changed
```

---

## 🧪 Testing

### Test 1: Verify Load Balancing

```bash
# Get ALB URL
ALB_URL=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' --output text)

# Visit multiple times and check hostname changes
for i in {1..5}; do
  curl http://$ALB_URL | jq '.hostname'
done

# Output should alternate between different instance IPs
```

### Test 2: Trigger Zero-Downtime Update

```bash
# Edit app.py version
sed -i 's/"version": "1.0.0"/"version": "1.0.1"/' app/app.py

# Commit and push
git add app/app.py
git commit -m "bump version to 1.0.1"
git push origin main

# Watch GitHub Actions complete
# Then refresh ALB URL - version should be 1.0.1
# Hostname may alternate during rollout (old/new instances)
```

### Test 3: Check Health Status

```bash
# Access health endpoint
curl http://$ALB_URL/health

# Output: {"status": "UP"} with HTTP 200

# Check target group health in AWS Console:
# EC2 → Target Groups → Select TG → Targets tab
# All instances should show "Healthy"
```

---

## 🔧 Troubleshooting Guide

### Problem 1: ALB Returns 502 Bad Gateway

**Cause:** Load balancer can't reach application on port 5000

**Solutions:**

1. **Check port mapping in UserData:**
```bash
# SSH to instance via Session Manager
# AWS Console → Systems Manager → Session Manager → Start session

# Inside instance terminal:
sudo docker ps

# Look for: -p 5000:5000 mapping
# If missing, instance wasn't updated with latest Launch Template
```

2. **Check security group allows port 5000:**
```bash
# AWS Console → EC2 → Security Groups → app security group
# Inbound rules should have:
#   - Port 5000, Protocol TCP, Source: ALB security group
```

3. **Verify Flask app is listening:**
```bash
# In Session Manager:
sudo docker logs hasa-app

# Check for "Running on 0.0.0.0:5000"
```

4. **Check target group health:**
```bash
# AWS Console → EC2 → Target Groups → Select TG
# Click Targets tab
# If "Unhealthy", click instance name
# Description shows why (e.g., "Health check failed with HTTP code 502")
```

**Fix:** If instances are unhealthy after update, manually terminate them:
```bash
aws ec2 terminate-instances --instance-ids i-xxxxx i-yyyyy --region us-east-1
# ASG will automatically launch replacement instances
```

---

### Problem 2: Docker Login Fails (Non-TTY Error)

**Error Message:**
```
Error: Cannot perform an interactive login from a non TTY device
```

**Cause:** UserData script runs non-interactively; Docker can't prompt for password

**Solution:** Use `--password-stdin` to pipe password instead of interactive prompt

```bash
# ❌ Wrong (interactive):
aws ecr get-login-password | docker login ...

# ✅ Correct (non-interactive):
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

---

### Problem 3: AWS CLI Syntax Error

**Error Message:**
```
aws: error: argument command: Invalid choice, valid choices are: [list of commands]
```

**Cause:** Capitalized ECR command (`aws ECR` instead of `aws ecr`)

```bash
# ❌ Wrong (capitalized):
aws ECR get-login-password

# ✅ Correct (lowercase):
aws ecr get-login-password
```

---

### Problem 4: Instance Refresh Stuck in InProgress

**Cause 1: Application failing health checks**

```bash
# Check ALB target health:
# AWS Console → EC2 → Target Groups → Targets tab
# If showing "Unhealthy", expand description for reason

# Common reasons:
# - Port 5000 not listening (app not running)
# - Docker container crashed (check docker logs)
# - Security group blocking traffic
```

**Cause 2: Old refresh still running**

```bash
# Cancel stuck refresh:
aws autoscaling cancel-instance-refresh \
  --auto-scaling-group-name "hasa-app-asg" \
  --region us-east-1

# Or via AWS Console:
# EC2 → Auto Scaling Groups → hasa-app-asg
# → Instance Refresh tab → Cancel
```

**Cause 3: InstanceWarmup timeout too short**

```bash
# Current setting in deploy.yml:
# InstanceWarmup=300 (5 minutes)

# This gives EC2 time to:
# - Update yum packages (2-3 mins)
# - Pull Docker image from ECR (1-2 mins)
# - Run container (10 secs)
# - Pass ALB health check (30 secs)

# If still timing out, increase in deploy.yml:
# InstanceWarmup=600 (10 minutes)
```

---

### Problem 5: Terraform State Lock

**Error Message:**
```
Error acquiring the state lock: ConditionalCheckFailedException
```

**Cause:** Another `terraform apply` is running, preventing concurrent changes

**Solution:**

```bash
# If stuck (another process crashed):
aws dynamodb scan \
  --table-name hasa-app-terraform-locks \
  --region us-east-1

# If LockID exists, manually delete:
aws dynamodb delete-item \
  --table-name hasa-app-terraform-locks \
  --key '{"LockID": {"S": "hasa-app-terraform-state-XXXX/prod/terraform.tfstate"}}' \
  --region us-east-1

# Then retry terraform apply
```

---

### Problem 6: ECR Image Not Found

**Error Message:**
```
Error response from daemon: pull access denied for XXXX.dkr.ecr.us-east-1.amazonaws.com/hasa-app-app, repository not found
```

**Cause:** ECR repository doesn't exist or image not pushed

**Solution:**

```bash
# Check if repository exists:
aws ecr describe-repositories --region us-east-1

# If missing, create it:
aws ecr create-repository --repository-name hasa-app-app --region us-east-1

# Push image manually:
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker tag hasa-app:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hasa-app-app:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hasa-app-app:latest
```

---

### Problem 7: Variable Expansion in Heredoc

**Symptom:** Docker login command shows literal `$ECR_REGISTRY` instead of actual registry URL

**Cause:** Using `<<'EOF'` (single quotes) prevents variable expansion

```bash
# ❌ Wrong (quotes prevent expansion):
NEW_USER_DATA=$(base64 -w 0 <<'EOF'
aws ecr login ... $ECR_REGISTRY
EOF
)

# ✅ Correct (no quotes allow expansion):
NEW_USER_DATA=$(base64 -w 0 <<EOF
aws ecr login ... $ECR_REGISTRY
EOF
)
```

---

### Problem 8: Permission Denied Running Docker

**Error Message:**
```
Got permission denied while trying to connect to Docker daemon
```

**Cause:** User not in docker group

**Solution:** Already in UserData:
```bash
usermod -a -G docker ec2-user
# User can now run docker commands without sudo
```

---

## 📊 Monitoring & Debugging

### Check Instance Logs

```bash
# Via Session Manager (no SSH keys needed):
aws ssm start-session --target i-xxxxxxxxxxxxx --region us-east-1

# Inside instance:
sudo cat /var/log/user-data.log      # Initialization logs
sudo docker ps -a                     # Container status
sudo docker logs hasa-app             # Application logs
```

### Monitor Auto Scaling Activity

```bash
# View all ASG activities:
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "hasa-app-asg" \
  --region us-east-1 \
  --query 'Activities[0:5]'

# Output shows instance launches, terminations, health check failures
```

### Check ALB Health

```bash
# View target health:
aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/hasa-app-tg/*" \
  --region us-east-1

# Output shows: Healthy, Unhealthy, Initial, or Draining
```

### Monitor GitHub Actions

**URL:** `https://github.com/YOUR-USERNAME/high-availability-secure-architecture-cicd/actions`

Watch:
- Build logs in real-time
- Docker build output
- Terraform changes
- Instance Refresh progress

---


## 🗑️ Cleanup

**Delete all resources to stop charges:**

```bash
cd terraform

# View what will be deleted:
terraform plan -destroy

# Delete everything:
terraform destroy

# Type 'yes' when prompted
```

**Manual cleanup:**

```bash
# Delete S3 bucket (Terraform won't delete if not empty):
aws s3 rm s3://hasa-app-terraform-state-XXXX --recursive
aws s3api delete-bucket --bucket hasa-app-terraform-state-XXXX --region us-east-1

# Delete DynamoDB table:
aws dynamodb delete-table --table-name hasa-app-terraform-locks --region us-east-1

# Delete ECR repository:
aws ecr delete-repository --repository-name hasa-app-app --force --region us-east-1
```

---

## 🎓 Key Concepts & Lessons Learned

### 1. Port Mapping Matters

The biggest gotcha: ALB talks to EC2 on port 5000, but you might map Docker to port 80 on the host.

```
User → ALB:80 → EC2:5000 → Container:5000
                            ↓
                    Flask app listening
```

If container binds to port 80 on host, ALB's port 5000 check fails = 502 error.

### 2. Instance Refresh is Production Magic

Without Instance Refresh:
- Manual SSH into each instance
- `docker pull` and `docker run` by hand
- Risk of inconsistent deployments
- Potential downtime

With Instance Refresh:
- ASG automatically replaces instances
- Respects health checks
- Waits before removing old instance
- Zero downtime guaranteed

### 3. Multi-AZ ≠ Just High Availability

Having instances in us-east-1a and us-east-1b means:
- If entire AZ fails, your app still runs
- Load balancer in both subnets
- ASG replaces failed instances in another AZ

### 4. IAM Roles > Hardcoded Credentials

Never put AWS keys in code. Use IAM roles:
```bash
# ✅ Right (instance assumes role):
aws ecr get-login-password  # Works automatically

# ❌ Wrong (credentials in UserData):
AWS_ACCESS_KEY_ID=XXXX aws ecr get-login-password
```

### 5. Variable Expansion in Scripts

Bash heredocs have tricky quoting rules:

```bash
# This won't work (quotes prevent expansion):
NEW_DATA=$(cat <<'EOF'
some text $VAR_NAME
EOF
)

# This works (expansion happens):
NEW_DATA=$(cat <<EOF
some text $VAR_NAME
EOF
)
```

### 6. Health Checks are Non-Negotiable

ALB pings `/health` endpoint every 30 seconds. If it fails:
- Instance marked Unhealthy
- ASG terminates it
- New instance launched
- Automatic self-healing ✅

Your app must respond to `/health` quickly.

### 7. AWS CLI v1 vs v2 Differences

Amazon Linux 2 ships with AWS CLI v1. Some commands behave differently:

```bash
# Both versions support this:
aws ecr get-login-password --region us-east-1 | docker login ...

# Use this syntax for maximum compatibility
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

---

## 🤝 Contributing

This is a learning project. To improve it:

1. Fork the repository
2. Create a feature branch
3. Make improvements
4. Submit a pull request

---

## 📝 License

This project is open source. Use it freely for learning and production deployments.

---

## 👤 Author

**Siddhesh** - DevOps Engineer Portfolio Project

**GitHub:** [Siddhesh-07](https://github.com/Siddhesh-07)

---

## 📞 Support & Questions

**Stuck on something?**

1. Check the **Troubleshooting Guide** above
2. Review **GitHub Actions logs**: Repository → Actions tab
3. Check **AWS CloudTrail** for API errors
4. Read **User Data logs** on instance: `/var/log/user-data.log`

**Architecture questions?**

Review the **Architecture Diagram** and **How It Works** sections above.

---

## 🎯 Next Steps for Improvement

This capstone covers the essentials. To level up:

- [ ] Add CloudWatch monitoring and alarms
- [ ] Implement canary deployments (10% → 50% → 100%)
- [ ] Add database layer (RDS/DynamoDB)
- [ ] Implement secrets management (AWS Secrets Manager)
- [ ] Add WAF (Web Application Firewall)
- [ ] Add Kubernetes (EKS) as alternative to ASG
- [ ] Implement blue-green deployments

---

**Congratulations! You've built a production-grade CI/CD platform. This is DevOps done right.** 🚀
