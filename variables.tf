
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {
  default = ""
}
variable "aws_key_name" {
  default = ""
}

variable "aws_region" {
  description = "EC2 Region for the VPC"
  default = "eu-west-1"
}

variable "amis" {
  type = "map"
  description = "AMIs by region"
  default = {
    eu-west-1 = "ami-0c35056a" # centos 6.8
  }
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default = "10.0.0.0/24"
}
