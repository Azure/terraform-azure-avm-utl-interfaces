variable "user_principal_type" {
  type        = string
  default     = "User"
  description = "This is so we can set the correct value in the CI/CD pipeline. In a real-world scenario, this would be set to 'User' or 'ServicePrincipal' based on the principal type you are assigning the role to."
}
