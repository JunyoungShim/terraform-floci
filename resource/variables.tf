# project
variable "system_name" {
  type = string
}
variable "enviroment" {
  type = string
}

# aws
variable "region" {
  type = string
}
variable "azs" {
  type = list(string)
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