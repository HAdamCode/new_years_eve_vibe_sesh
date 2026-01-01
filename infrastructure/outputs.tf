output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = module.cognito_user_pool.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN."
  value       = module.cognito_user_pool.arn
}
