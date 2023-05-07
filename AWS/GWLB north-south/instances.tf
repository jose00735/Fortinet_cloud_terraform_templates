resource "aws_key_pair" "key_LB" {
  key_name   = "key_LB"
  public_key = file("/home/ec2-user/.ssh/id_rsa.pub")
}

module "fortigates" {
  source                 = "./modules/FGT"
  for_each               = local.fgt_names
  admin-user             = var.admin-user
  password               = var.password
  private_subnet_address = local.subnets_definitions_mapped_private
  GWLB_interface_ip      = local.Private_ips_GWLB[index(keys(local.fgt_names), each.key)]
  key_name               = aws_key_pair.key_LB.key_name
  private_interface_id   = aws_network_interface.Interfaces[local.fgt_private_interfaces[each.key]["Private_interface"]].id
  public_interface_id    = aws_network_interface.Interfaces[local.fgt_public_interfaces[each.key]["Public_interface"]].id
  tags                   = local.tags
  arch                   = var.arch
  ver                    = var.ver
  license                = var.license
}

module "apache" {
  source               = "./modules/Linux"
  for_each             = local.linux_private_interfaces
  client_number        = local.linux_private_interfaces[each.key]["vpc"]
  key_name             = aws_key_pair.key_LB.key_name
  private_interface_id = aws_network_interface.Interfaces[each.key].id
  tags                 = local.tags
}