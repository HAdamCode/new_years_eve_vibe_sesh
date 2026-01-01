resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = var.user_pool_client_name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}
