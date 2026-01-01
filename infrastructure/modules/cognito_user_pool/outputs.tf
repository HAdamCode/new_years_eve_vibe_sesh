output "id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "arn" {
  description = "Cognito User Pool ARN."
  value       = aws_cognito_user_pool.this.arn
}
