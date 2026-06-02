# project
variable "aws_region" {
  type = string
}
variable "system_name" {
  type = string
}
variable "environment" {
  type = string
}

# network
variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "protect_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}