terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "random_password" "database" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "app_database" {
  name        = "${var.project_name}/${var.environment}/database-credentials"
  description = "Database credentials for ${var.project_name} (${var.environment})"

  # Lab setting only: deletes immediately instead of holding the name
  # for a 7 to 30 day recovery window. Never use 0 in production.
  recovery_window_in_days = 0

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "app_database" {
  secret_id = aws_secretsmanager_secret.app_database.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.database.result
    host     = "db.example.internal"
    port     = 5432
    dbname   = "${var.project_name}-db"
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name        = "${var.project_name}/${var.environment}/api-keys"
  description = "Third-party API keys for ${var.project_name}"

  recovery_window_in_days = 0

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    stripe_key   = "sk_test_placeholder"
    sendgrid_key = "SG.placeholder"
  })
}
