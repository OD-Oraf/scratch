terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
  default     = "OD-Oraf"
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
  default     = "scratch"
}

# ── Data: latest Amazon Linux 2023 AMI ─────────────────────────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── GitHub OIDC provider ──────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ── IAM role with SSM + GitHub OIDC access ────────────────────
resource "aws_iam_role" "esb_ssm_role" {
  name = "esb-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# ── S3 bucket for file transfer between EC2 machines ─────────
resource "aws_s3_bucket" "transfer" {
  bucket = "esb-to-ace-transfer"

  tags = {
    Name        = "esb-to-ace"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy" "s3_transfer" {
  name = "esb-s3-transfer"
  role = aws_iam_role.esb_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.transfer.arn,
          "${aws_s3_bucket.transfer.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.esb_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "esb_profile" {
  name = "esb-ssm-instance-profile"
  role = aws_iam_role.esb_ssm_role.name
}

# ── Security group (SSM needs outbound HTTPS only) ────────────
resource "aws_security_group" "esb_sg" {
  name        = "esb-ssm-sg"
  description = "Allow outbound HTTPS for SSM agent"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for SSM agent"
  }
}

# ── EC2: esb-build ────────────────────────────────────────────
resource "aws_instance" "esb_build" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.esb_profile.name
  vpc_security_group_ids = [aws_security_group.esb_sg.id]

  tags = {
    Name = "esb-build"
  }
}

# ── EC2: esb-deploy ───────────────────────────────────────────
resource "aws_instance" "esb_deploy" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.esb_profile.name
  vpc_security_group_ids = [aws_security_group.esb_sg.id]

  tags = {
    Name = "esb-deploy"
  }
}

# ── Outputs ───────────────────────────────────────────────────
output "esb_build_instance_id" {
  description = "Instance ID of esb-build (use with: aws ssm start-session --target <id>)"
  value       = aws_instance.esb_build.id
}

output "esb_deploy_instance_id" {
  description = "Instance ID of esb-deploy (use with: aws ssm start-session --target <id>)"
  value       = aws_instance.esb_deploy.id
}

output "esb_ssm_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC (use with aws-actions/configure-aws-credentials)"
  value       = aws_iam_role.esb_ssm_role.arn
}

output "transfer_bucket" {
  description = "S3 bucket for transferring files between instances"
  value       = aws_s3_bucket.transfer.id
}
