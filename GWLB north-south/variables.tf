variable "vpc_network_definitions" {
  type = map(map(any))
  default = {
    "Secure_VPC" = {
      "cidr_vpc_block"  = "10.0.0.0/16"
      "security_role"   = true
      "available_zones" = 1
    },
    "Client1" = {
      "cidr_vpc_block"  = "10.1.0.0/16"
      "security_role"   = false
      "available_zones" = 1
    }
    "Client2" = {
      "cidr_vpc_block"  = "10.2.0.0/16"
      "security_role"   = false
      "available_zones" = 1
    }
  }
}

variable "password" {
  type    = string
  default = "password123"
}


variable "admin-user" {
  type    = string
  default = "eljose"
}

variable "arch" {
  type    = string
  default = "x86_64"
}

variable "ver" {
  type    = string
  default = "7.2.4"
}

variable "license" {
  type    = string
  default = "payg"
}
