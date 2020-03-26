variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "infra_tags" {
  type = object({
    Environment = string
  })
  default = {
      Environment = "testing"
    }
}

variable "environment" {
  type = string
  default = "testing"
}

variable "prefix_cidr_block" {
  type = string
  default = "10.0"
}

#limeted to 5
variable "num_subnet_public" {
  type    = number
  default = 2
}

variable "num_subnet_private" {
  type    = number
  default = 2
}


locals {
  total_instances = 2
  instance_type   = "t2.micro"
  env             = "testing"
  ingress_ports   = [80, 22]
}
