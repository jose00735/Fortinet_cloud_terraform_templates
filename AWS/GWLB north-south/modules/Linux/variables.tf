variable "key_name" {}
variable "private_interface_id" {}
variable "client_number" {}
variable "tags" {}

variable "bootstrap" {
    default = "/home/ec2-user/Terraform/GWLB north-south/modules/Linux/bootstrap.sh"
}