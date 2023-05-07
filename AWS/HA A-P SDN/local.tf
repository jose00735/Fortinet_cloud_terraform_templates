locals {
  tags = {
    "Project" = "Terraform Templates"
    "Deploy"  = "A-H"
  }

  Subnets_definitions = {
    "FGT1-Public" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 0)
      "index" = 0
    }
    "FGT2-Public" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 1)
      "index" = 0
    }
    "FGT1-Private" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 2)
      "index" = 1
    }
    "FGT2-Private" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 3)
      "index" = 1
    }
    "FGT1-HA" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 4)
      "index" = 2
    }
    "FGT2-HA" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 5)
      "index" = 2
    }
    "FGT1-mgmt" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 6)
      "index" = 3
    }
    "FGT2-mgmt" = {
      "cidr_block" = cidrsubnet(var.vpc_cidr, 8, 7)
      "index" = 3
    }
  }
  Global_ingress = [
    {
      description = "allow HTTPS"
      from_port   = 10443
      to_port     = 10443
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    },
    {
      description = "allow SSH"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    },
    {
      description = "allow SSH protected device"
      from_port   = 2222
      to_port     = 2222
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    },
    {
      description = "allow http protected device"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  ]

  Global_egress = [
    {
      description = "allow all"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "-1"
    }
  ]

  Subnets_definitions_H3  = { for k, v in local.Subnets_definitions : "${k}" => v if endswith(k, "mgmt") == false }

  interfaces_EIP_names_H3 = { for k, v in local.Subnets_definitions : "${k}" => v if endswith(k, "HA") == true || k == "FGT1-Public" }

  interfaces_EIP_names    = { for k, v in local.Subnets_definitions : "${k}" => v if endswith(k, "mgmt") == true || k == "FGT1-Public" }

  Private_subnets = { for k, v in local.Subnets_definitions : "${k}" => v if endswith(k, "Private") == true }

  fgt_interfaces = {
    "FGT1" = { for k, v in local.Subnets_definitions : "${k}" => {"id" = aws_network_interface.FGT_Interfaces[k].id, "gateway_ip" = cidrhost(v["cidr_block"], 1), "index" = v["index"]} if startswith(k, "FGT1") == true }
    "FGT2" = { for k, v in local.Subnets_definitions : "${k}" => {"id" = aws_network_interface.FGT_Interfaces[k].id, "gateway_ip" = cidrhost(v["cidr_block"], 1), "index" = v["index"]} if startswith(k, "FGT2") == true }
  }
  fgt_interfaces_H3 = {
    "FGT1" = { for k, v in local.Subnets_definitions : "${k}" => {"id" = aws_network_interface.FGT_Interfaces[k].id, "gateway_ip" = cidrhost(v["cidr_block"], 1), "index" = v["index"]} if startswith(k, "FGT1") == true && endswith(k, "mgmt") == false }
    "FGT2" = { for k, v in local.Subnets_definitions : "${k}" => {"id" = aws_network_interface.FGT_Interfaces[k].id, "gateway_ip" = cidrhost(v["cidr_block"], 1), "index" = v["index"]} if startswith(k, "FGT2") == true && endswith(k, "mgmt") == false }
  }

  fgt_roles = {
    "FGT1" = "Master"
    "FGT2" = "Slave"
  }

  linux_ip = {
    "FGT1" = cidrhost(local.Private_subnets["FGT1-Private"]["cidr_block"], 100)
    "FGT2" = cidrhost(local.Private_subnets["FGT2-Private"]["cidr_block"], 100)
  }

  ha_peer_ip = {
    "FGT1" = { "ha_ip" = cidrhost(local.Subnets_definitions["FGT1-HA"]["cidr_block"], 10) , "ha_peer_ip" = cidrhost(local.Subnets_definitions["FGT2-HA"]["cidr_block"], 10), "mgmt_gw" = cidrhost(local.Subnets_definitions["FGT1-mgmt"]["cidr_block"], 1)}
    "FGT2" = { "ha_ip" = cidrhost(local.Subnets_definitions["FGT2-HA"]["cidr_block"], 10) , "ha_peer_ip" = cidrhost(local.Subnets_definitions["FGT1-HA"]["cidr_block"], 10), "mgmt_gw" = cidrhost(local.Subnets_definitions["FGT2-mgmt"]["cidr_block"], 1)}
  }

  license_file = var.license == "payg" ? "" : 

}

data "aws_availability_zones" "available" {}
