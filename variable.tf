variable "dev_region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "stg_region" {
  description = "aws region"
  type        = string
  default     = "us-east-2"
}

variable "prd_region" {
  description = "aws region"
  type        = string
  default     = "us-west-1"
}

variable "dev_az_1" {
  description = "dev env az 1"
  type        = string
  default     = "us-east-1a"
}

variable "dev_az_2" {
  description = "dev env az 1"
  type        = string
  default     = "us-east-1b"
}

variable "stg_az_1" {
  description = "stg env az 1"
  type        = string
  default     = "us-east-2a"
}

variable "stg_az_2" {
  description = "stg envaz 2"
  type        = string
  default     = "us-east-2c"
}

variable "prd_az_1" {
  description = "prd env az 1"
  type        = string
  default     = "us-west-1a"
}

variable "prd_az_2" {
  description = "prd env az 2"
  type        = string
  default     = "us-west-1c"
}
