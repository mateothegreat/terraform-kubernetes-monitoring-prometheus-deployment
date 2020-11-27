variable "product_name" {

    type = string

}

variable "cluster_name" {

    type = string

}

variable "environment_name" {

    type = string

}

variable "host" {

    type        = string
    description = "url to cluster api"

}

variable "token" {

    type        = string
    description = "api token"

}

variable "insecure" {

    type        = bool
    description = "skip ssl certificate verification"
    default     = false

}

variable "s3_aws_access_key_id" {

    type    = string
    default = ""

}

variable "s3_aws_secret_access_key" {

    type    = string
    default = ""

}

variable "s3_bucket" {

    type    = string
    default = ""

}

variable "s3_endpoint" {

    type    = string
    default = "s3.us-east-1.amazonaws.com"

}
