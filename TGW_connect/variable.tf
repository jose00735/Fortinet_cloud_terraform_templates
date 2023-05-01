variable "fgt_interface_definitions"{
    type = map(string) 
    default = {
        "public" = "10.0.0.0/25"
        "private" = "10.0.0.128/26"
        "TGW" = "10.0.0.192/26"
    }
}

variable "Clients_definitions"{
    type = map(map(any)) 
    default = {
        "cliente1" = {
            "network_address" = "10.0.1.0"
            "subnet_mask" = 24
        }
        "cliente2" = {
            "network_address" = "10.0.2.0"
            "subnet_mask" = 24
        }
        "cliente3" = {
            "network_address" = "10.0.3.0"
            "subnet_mask" = 24
        }
    }
}

variable "TGW_Cidr_definition"{
    type = map(map(any)) 
    default = {
        "TGW" = {
            "network_address" = "10.0.254.0"
            "subnet_mask" = 24
            "transit_gateway_address" = "10.0.254.10"
        }
    }
}

variable "bootstrap" {
    type = string
    default = "/home/ec2-user/Terraform/TGW_connect/bootstrap.sh"
}

variable "password" {
    type = string
    default = "password123"
}


variable "admin-user" {
    type = string
    default = "admin-user"
}

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
