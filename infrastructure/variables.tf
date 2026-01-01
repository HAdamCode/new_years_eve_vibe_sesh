variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "user_pool_name" {
  type        = string
  description = "Name for the Cognito User Pool."
  default     = "core-user-pool"
}
