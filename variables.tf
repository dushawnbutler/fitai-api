variable "aws_region" {
  description = "AWS Region for the project."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Short name used in AWS resource names."
  type        = string
  default     = "fitai-tracker"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "app_repository_url" {
  description = "HTTPS Git URL of your Node.js API repository."
  type        = string

  validation {
    condition     = startswith(var.app_repository_url, "https://")
    error_message = "app_repository_url must be an HTTPS Git URL."
  }
}

variable "app_port" {
  description = "Port on which the Node.js API listens."
  type        = number
  default     = 3000
}

variable "instance_type" {
  description = "EC2 instance type for the development API."
  type        = string
  default     = "t3.micro"
}

variable "allowed_client_cidr" {
  description = "Your current public IPv4 address followed by /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_client_cidr, 0)) && endswith(var.allowed_client_cidr, "/32")
    error_message = "Enter a valid single IPv4 address followed by /32."
  }
}
