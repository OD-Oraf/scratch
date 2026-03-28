terraform {
  required_version = ">= 1.0.0" # Ensure that the Terraform version is 1.0.0 or higher

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 4.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

provider "aws" {
  region = "us-east-1" # Set the AWS region to US East (N. Virginia)
}

resource "aws_instance" "aws_example" {
  tags = {
    Name = "ExampleInstance" # Tag the instance with a Name tag for easier identification
  }
}

locals {
  name_prefix = "github-oidc"
}

################################################################################
# OIDC
################################################################################
# ── GitHub OIDC provider ──────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ── IAM role for GitHub Actions → ECS deploy ─────────────────
resource "aws_iam_role" "github_actions_ecs_deploy" {
  name = "${local.name_prefix}-github-actions-ecs-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
            "token.actions.githubusercontent.com:sub" = [
              "repo:OD-Oraf/scratch:*",
              "repo:OD-Oraf/ecs-deployment-automation:*",
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-github-actions-ecs-deploy"
  }
}

resource "aws_iam_role_policy" "github_actions_ecs_deploy" {
  name = "${local.name_prefix}-ecs-deploy-policy"
  role = aws_iam_role.github_actions_ecs_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "*"
      },
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
}