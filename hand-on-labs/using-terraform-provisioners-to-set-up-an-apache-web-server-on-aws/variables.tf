variable "product_name" {
  description = "Product name"
  type        = string
  default     = "ProductA"
}

variable "environment" {
  description = "Product environment"
  type        = string
  default     = "Dev"
}

variable "public_key_path" {
  description = "SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}
