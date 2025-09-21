# Terraform AWS Windows Infrastructure

This repository provisions a **modular, production-ready Windows-based environment on AWS** using Terraform.  
It follows best practices for **modularity, tagging, CloudWatch monitoring, and secure networking**.  

---

## 📂 Repository Structure

```bash
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules
│   ├── vpc
│   ├── security-group
│   ├── ec2
│   ├── cloudwatch
│   ├── iam
│   └── sns


🚀 Root Module (main.tf)

The root module orchestrates the deployment by calling all child modules:

VPC → Creates networking (VPC, subnets, routing).

Security Groups → Creates role-based security groups (e.g., RDP, web).

EC2 Instances → Deploys Windows servers with customizable networking.

IAM Roles → Creates IAM roles and attaches managed policies.

SNS → Creates topics and email subscriptions for notifications.

CloudWatch Alarms → Monitors EC2 instances and triggers alerts.

All configurations (instances, alarms, IAM roles, topics) are passed via terraform.tfvars → ensuring flexible scaling without changing code.

🧩 Modules
1️⃣ VPC Module (modules/vpc)

Provisions:

VPC

Subnets (public/private)

Internet Gateway / NAT Gateway

Route tables

Ensures private-only networking (no public IPs by default).

Inputs: CIDR blocks, subnets, AZs.

2️⃣ Security Group Module (modules/security-group)

Creates security groups dynamically.

Example: rdp_jump, web, db.

Inputs:

Map of rules per SG (ingress, egress).

Tags.

Outputs SG IDs, referenced by EC2 and interfaces.

3️⃣ EC2 Module (modules/ec2)

Deploys Windows Server instances.

Supports:

Multiple ENIs (via dynamic blocks).

Availability Zone selection.

EBS optimization toggle.

Dynamic metadata options.

Interfaces defined like:

interfaces = [
  {
    name              = "eth0"
    device_index      = 0
    private_ips       = []
    cidr_block        = "10.0.1.0/24"
    sg_key            = ["rdp_jump"]
    source_dest_check = true
  }
]

4️⃣ IAM Module (modules/iam)

Creates IAM roles with attached managed policies.

Policies passed as list of ARNs.

Example:

roles = {
  ec2_role = {
    assume_policy = data.aws_iam_policy_document.ec2_assume.json
    policies      = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }
}

5️⃣ SNS Module (modules/sns)

Creates SNS Topics.

Supports multiple email subscriptions per topic.

Example:

topics = {
  alerts = {
    name = "infra-alerts"
    email_subscriptions = ["ops@example.com", "admin@example.com"]
  }
}

6️⃣ CloudWatch Module (modules/cloudwatch)

Monitors EC2 metrics.

Supports alarm groups → one key for multiple alarms, applied to multiple instances.

Example tfvars:

cloudwatch_alarm_groups = {
  cpu_group = {
    alarms = [
      {
        name        = "HighCPU"
        metric_name = "CPUUtilization"
        threshold   = 80
        statistic   = "Average"
        period      = 300
        evaluation_periods = 2
        comparison_operator = "GreaterThanOrEqualToThreshold"
      }
    ]
    instances = ["jump1", "jump2"]
    sns_topic = "alerts"
  }
}

🔗 How Modules Relate
flowchart TD
  A[main.tf] --> B[VPC Module]
  A --> C[Security Group Module]
  A --> D[EC2 Module]
  A --> E[IAM Module]
  A --> F[SNS Module]
  A --> G[CloudWatch Module]

  D --> C
  D --> B
  G --> D
  G --> F


VPC → provides subnets for EC2.

Security Groups → attached to ENIs in EC2.

IAM Roles → attached to EC2 for SSM/permissions.

SNS → notifications for CloudWatch alarms.

CloudWatch → monitors EC2 metrics and triggers SNS topics.

⚙️ Usage

Configure terraform.tfvars:

region = "eu-west-1"

vpc_config = {
  cidr_block = "10.0.0.0/16"
  subnets    = { "private1" = "10.0.1.0/24" }
}

instances = {
  jump1 = {
    ami              = "ami-0abcdef1234567890"
    instance_type    = "t3.medium"
    availability_zone = "eu-west-1a"
    ebs_optimized     = true
    interfaces = [
      {
        name              = "eth0"
        device_index      = 0
        private_ips       = []
        cidr_block        = "10.0.1.0/24"
        sg_key            = ["rdp_jump"]
        source_dest_check = true
      }
    ]
  }
}


Initialize:

terraform init


Validate:

terraform plan


Deploy:

terraform apply

🏷️ Best Practices Followed

No secrets in tfvars → use SSM/Secrets Manager manually if needed.

No public IPs → jump boxes require private access.

Dynamic blocks → for scalable interfaces, alarms, policies.

Explicit region declaration.

TLS version pinned for provider.

📌 Next Steps

Extend EC2 userdata/bootstrap for domain join.

Add ASGs and Load Balancers for scaling.

Extend alarms for memory & disk using CloudWatch Agent.