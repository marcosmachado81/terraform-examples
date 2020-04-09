variable "moduleIdentification" {
  type = string
  default = "Network"
}
variable "team" {
  type = string
  default = "Operations"
}
variable "costCenter" {}

variable "vpc_cidr_block" {
  type    =  string
  default = "10.0.0.0/16"
}

variable "vpc_cidr_block_testing" {
  type    =  string
  default = "172.16.0.0/16"
}

variable "prefix_cidr_block" {
  type = string
  default = "10.0"
}

variable "prefix_cidr_block_testing" {
  type = string
  default = "172.16"
}

variable "cidr_prefix_start_public" {
  type = number
  default = 0
}

variable "n_subnet_public" {
  type = number
  default = 2
}

variable "n_subnet_private" {
  type = number
  default = 2
}

variable "cidr_prefix_start_private" {
  type = number
  default = 5
}
