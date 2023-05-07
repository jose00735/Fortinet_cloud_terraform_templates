locals {
  AMI = join("", [for item in local.AMIs_data : item.Architecture == var.arch && item.Version == var.ver && item.License == var.license ? item.ImageId : ""])
  AMIs_data = jsondecode(file("/home/ec2-user/Terraform/Amis.json"))

  fgt_config = var.role == "Master" && var.HA3 == false ? "${path.module}/fgt_master.conf" : var.role == "Master" && var.HA3 == true ? "${path.module}/fgt_master_HA3.conf" : var.role == "Slave" && var.HA3 == false ? "${path.module}/fgt_slave.conf" : "${path.module}/fgt_slave_HA3.conf"
}