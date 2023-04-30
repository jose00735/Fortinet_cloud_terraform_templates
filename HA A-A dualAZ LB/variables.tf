variable "arch" {
    type = string
    default = "x86_64"
}

variable "ver" {
    type = string
    default = "7.2.4"
}

variable "license" {
    type = string
    default = "payg"
}

variable "listener_ports" {
  description = "Ports for the load balancer listeners"
  type        = list(number)
  default     = [8080, 2222]
}

