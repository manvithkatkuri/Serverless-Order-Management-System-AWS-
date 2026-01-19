variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "order-system"
}

variable "notification_email" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    Project = "order-system"
    Owner   = "manvith"
  }
}
