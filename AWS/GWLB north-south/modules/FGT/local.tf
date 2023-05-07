locals {
  AMI = join("", [for item in local.AMIs_data : item.Architecture == var.arch && item.Version == var.ver && item.License == var.license ? item.ImageId : ""])
  AMIs_data = jsondecode(file("/home/ec2-user/Terraform/Amis.json"))
}