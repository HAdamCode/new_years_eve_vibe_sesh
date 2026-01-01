variable "user_pool_name" {
  type        = string
  description = "Name for the Cognito User Pool."
}

variable "user_pool_client_name" {
  type        = string
  description = "Name for the Cognito User Pool client."
  default     = "core-user-pool-client"
}
