variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "HA3" {
  type    = bool
  default = false
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

variable "license1_dir" {}
variable "license2_dir" {}

