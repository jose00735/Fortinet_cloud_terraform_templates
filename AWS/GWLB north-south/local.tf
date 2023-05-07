locals {
  tags = {
    "project" = "Terraform templates"
    "Lab"     = "North-South"
  }

  client_vpc_names = { for vpcs_names in keys(var.vpc_network_definitions) : "${vpcs_names}" => { "security_role" = "${var.vpc_network_definitions[vpcs_names]["security_role"]}" } if vpcs_names != "Secure_VPC" }

  subnets_definitions = flatten([for vpcs in keys(var.vpc_network_definitions) : [
    for az_index in range(var.vpc_network_definitions[vpcs]["available_zones"]) : [
      for public_private in range(2) :
      merge(var.vpc_network_definitions[vpcs], {
        "available_zone" = "${az_index}",
        "vpc"            = "${vpcs}",
        "subnet_role"    = public_private == 1 ? "Private" : var.vpc_network_definitions[vpcs]["security_role"] == "false" ? "GWLB" : "Public",
      "subnet_number" = public_private == 0 ? az_index : az_index + tonumber(var.vpc_network_definitions[vpcs]["available_zones"]) })
  ]]])

  subnets_definitions_mapped = { for subnet in local.subnets_definitions : "${subnet["subnet_role"]}-${subnet["vpc"]}-AZ-${data.aws_availability_zones.available.names[subnet["available_zone"]]}" => merge(subnet, { "cidr_subnet_block" = cidrsubnet(subnet["cidr_vpc_block"], 8, subnet["subnet_number"]) }) }

  interfaces_definitions = { for interface in keys(local.subnets_definitions_mapped) :
    "Interface-${local.subnets_definitions_mapped[interface]["subnet_role"]}-${local.subnets_definitions_mapped[interface]["vpc"]}-${data.aws_availability_zones.available.names[local.subnets_definitions_mapped[interface]["available_zone"]]}" =>
  merge(local.subnets_definitions_mapped[interface], { "subnet_name" = interface }) if local.subnets_definitions_mapped[interface]["subnet_role"] == "Private" || local.subnets_definitions_mapped[interface]["subnet_role"] == "Public" }

  subnets_definitions_mapped_private = [for subnet in local.subnets_definitions_mapped : subnet["cidr_subnet_block"] if subnet["security_role"] == "false" && subnet["subnet_role"] == "Private"]

  subnets_definitions_mapped_public = { for subnets in keys(local.subnets_definitions_mapped) : "${subnets}" => { "vpc" = local.subnets_definitions_mapped[subnets]["vpc"] } if local.subnets_definitions_mapped[subnets]["subnet_role"] != "Private" }

  subnet_gwlb_names = { for subnets_names in keys(local.subnets_definitions_mapped) : "${subnets_names}" => { "cidr_block" = local.subnets_definitions_mapped[subnets_names]["cidr_subnet_block"] } if local.subnets_definitions_mapped[subnets_names]["security_role"] == "true" && local.subnets_definitions_mapped[subnets_names]["subnet_role"] == "Private" }

  subnet_endpoint_names = { for subnets in keys(local.subnets_definitions_mapped) :
  "${local.subnets_definitions_mapped[subnets]["vpc"]}-${data.aws_availability_zones.available.names[local.subnets_definitions_mapped[subnets]["available_zone"]]}" => { "subnet" = "${subnets}", "vpc" = "${local.subnets_definitions_mapped[subnets]["vpc"]}" } if local.subnets_definitions_mapped[subnets]["security_role"] == "false" && local.subnets_definitions_mapped[subnets]["subnet_role"] == "GWLB" }

  subnet_private_names = { for subnets in keys(local.subnets_definitions_mapped) :
  "${local.subnets_definitions_mapped[subnets]["vpc"]}-${data.aws_availability_zones.available.names[local.subnets_definitions_mapped[subnets]["available_zone"]]}" => { "subnet" = "${subnets}", "vpc" = "${local.subnets_definitions_mapped[subnets]["vpc"]}" } if local.subnets_definitions_mapped[subnets]["security_role"] == "false" && local.subnets_definitions_mapped[subnets]["subnet_role"] == "Private" }

  fgt_names = { for Names_index in range(var.vpc_network_definitions["Secure_VPC"]["available_zones"]) : "Fortigate-${data.aws_availability_zones.available.names[Names_index]}" =>
  { "Description" = "Fortigate located in the Secure VPC availability zone ${data.aws_availability_zones.available.names[Names_index]}", "available_zone" = Names_index } }

  linux_private_interfaces = { for Names_index in keys(local.interfaces_definitions) : "${Names_index}" => { "subnet_number" = local.interfaces_definitions[Names_index]["subnet_number"], "vpc" = local.interfaces_definitions[Names_index]["vpc"] } if local.interfaces_definitions[Names_index]["subnet_role"] == "Private" && local.interfaces_definitions[Names_index]["security_role"] == "false" }

  fgt_private_interfaces = { for intf_definitions in keys(local.interfaces_definitions) :
  "Fortigate-${data.aws_availability_zones.available.names[local.interfaces_definitions[intf_definitions]["available_zone"]]}" => { "Private_interface" = "${intf_definitions}" } if local.interfaces_definitions[intf_definitions]["security_role"] == "true" && local.interfaces_definitions[intf_definitions]["subnet_role"] == "Private" }

  fgt_public_interfaces = { for intf_definitions in keys(local.interfaces_definitions) :
  "Fortigate-${data.aws_availability_zones.available.names[local.interfaces_definitions[intf_definitions]["available_zone"]]}" => { "Public_interface" = "${intf_definitions}" } if local.interfaces_definitions[intf_definitions]["security_role"] == "true" && local.interfaces_definitions[intf_definitions]["subnet_role"] == "Public" }

  SG_ingress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 10443
      to_port     = 10443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 2222
      to_port     = 2232
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 1080
      to_port     = 1080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 6081
      to_port     = 6081
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  SG_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  Private_ips_GWLB = [for Private_ip in data.aws_network_interface.eni : Private_ip.private_ip]
}

data "aws_availability_zones" "available" {}
data "aws_network_interfaces" "GWLB_interfaces" {
  depends_on = [ aws_lb.gwlb ]
  filter {
    name   = "description"
    values = ["ELB gwy/GWLB*"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.VPCs["Secure_VPC"].id]
  }
}

data "aws_network_interface" "eni" {
  depends_on = [ aws_lb.gwlb ]
  for_each   = toset(data.aws_network_interfaces.GWLB_interfaces.ids)
  id         = each.value
}


