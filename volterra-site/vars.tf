variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "az" {
  description = "AWS Availability Zone"
  type        = string
  default     = "us-west-2a"
}

variable "aws_creds" {
  description = "VoltConsole AWS Credential name"
  type        = string
}

variable "api_p12_file" {
  description = "VoltConsole certificate for authentication"
  type        = string
}

variable "tenant" {
  description = "voltConsole tenant name"
  type        = string
}

variable "tenant_id" {
  description = "VoltConsole tenant id"
  type        = string
}

variable "site_name" {
  description = "VoltConsole Site Name"
  type        = string
}

variable "site_namespace" {
  description = "VoltConsole Namespace"
  type        = string
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
}

variable "global_network" {
  description = "Volterra Global Network name"
  type        = string
}
