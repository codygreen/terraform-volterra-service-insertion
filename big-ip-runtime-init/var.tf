variable "aws_site" {}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
  default     = "tf-demo-key"
}

variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-aws-bigip"
}

variable "AllowedIPs" {
  description = "List of allowed IP addresses to the BIG-IP management interfaces"
  type        = list(string)
}

variable "instance_count" {
  description = "Number of Bigip instances to create( From terraform 0.13, module supports count feature to spin mutliple instances )"
  type        = number
  default     = 2
}

variable "f5_username" {
  description = "The admin username of the F5 Bigip that will be deployed"
  default     = "bigipuser"
}
