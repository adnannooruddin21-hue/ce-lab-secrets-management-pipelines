data "aws_caller_identity" "current" {}
 
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # No thumbprint_list: since 2023 AWS validates this provider against its own
  # trusted CA store, and pinning a thumbprint only creates a rotation footgun.
}
 
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:YOUR_ORG/ce-lab-secrets-management-pipelines:*"
          }
        }
      }
    ]
  })
}
 
resource "aws_iam_role_policy" "secrets_read" {
  name = "secrets-read-only"
  role = aws_iam_role.github_actions.id
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.app_database.arn,
          aws_secretsmanager_secret.api_keys.arn
        ]
      }
    ]
  })
}
 
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}