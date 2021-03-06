#variable "aws-region" {
#  default     = "eu-west-1"
#  description = "Default AWS region"
#}

variable "cidr-start" {
  default     = "10.50"
  description = "Default CIDR block"
}

variable "environment-name" {
  default = "prod"
}
#chg
variable "assume_role_arn" {
  description = "arn for role to assume in separate identity account if used"
  default     = ""
}
