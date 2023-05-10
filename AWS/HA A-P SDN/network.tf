### VPC ###
resource "aws_vpc" "HA-A-P" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.tags, { "Name" = "HA-A-P VPC" })
}

## Subnets ##
resource "aws_subnet" "Subnets" {
  for_each          = var.HA3 ? local.Subnets_definitions_H3 : local.Subnets_definitions
  cidr_block        = each.value["cidr_block"]
  vpc_id            = aws_vpc.HA-A-P.id
  availability_zone = data.aws_availability_zones.available.names[startswith(each.key, "FGT1") == true ? 0 : 1]
  tags              = merge(local.tags, { "Name" = "${each.key}-subnet" })
}

## Security groups ##

resource "aws_security_group" "global" {
  name        = "Global SG"
  description = "allows whatever you put in the local rules"
  vpc_id      = aws_vpc.HA-A-P.id

  dynamic "ingress" {
    for_each = local.Global_ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = ingress.value.cidr_blocks
      protocol    = ingress.value.protocol
    }
  }

  dynamic "egress" {
    for_each = local.Global_egress
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      cidr_blocks = egress.value.cidr_blocks
      protocol    = egress.value.protocol
    }
  }
  tags = merge(local.tags, { "Name" = "Global SG" })
}

## Interfaces ##

resource "aws_network_interface" "FGT_Interfaces" {
  for_each        = var.HA3 ? local.Subnets_definitions_H3 : local.Subnets_definitions
  description = "FGT-Interface-${each.key}"
  source_dest_check = endswith(each.key, "Private") == true ? false : true
  subnet_id       = aws_subnet.Subnets[each.key].id
  private_ips     = [cidrhost(each.value["cidr_block"], 10)]
  security_groups = [aws_security_group.global.id]
  tags            = merge(local.tags, { "Name" = "FGT-Interface-${each.key}" })
}

resource "aws_network_interface" "Linux_Interfaces" {
  for_each        = local.Private_subnets
  subnet_id       = aws_subnet.Subnets[each.key].id
  private_ips     = [cidrhost(each.value["cidr_block"], 100)]
  security_groups = [aws_security_group.global.id]
  tags            = merge(local.tags, { "Name" = "Linux-Interface-${each.key}" })
}

## EIP ##

resource "aws_eip" "EIPs" {
  for_each                  = var.HA3 ? local.interfaces_EIP_names_H3 : local.interfaces_EIP_names
  vpc                       = true
  network_interface         = aws_network_interface.FGT_Interfaces[each.key].id
  associate_with_private_ip = aws_network_interface.FGT_Interfaces[each.key].private_ip
  tags            = merge(local.tags, { "Name" = "EIP-${each.key}" })
}

## internet gateway ##

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.HA-A-P.id
  tags   = merge(local.tags, { "Name" = "Gateway" })
}

## route table ##

resource "aws_route_table" "Routing_tables" {
  for_each = var.HA3 ? local.Subnets_definitions_H3 : local.Subnets_definitions
  vpc_id   = aws_vpc.HA-A-P.id

  route {
    cidr_block           = "0.0.0.0/0"
    gateway_id           = endswith(each.key, "Private") ? "" : aws_internet_gateway.gw.id
    network_interface_id = endswith(each.key, "Private") ? aws_network_interface.FGT_Interfaces[each.key].id : ""
  }

  tags = merge(local.tags, { "Name" = "${each.key}-rt" })
}

resource "aws_route_table_association" "Routing_tables_association" {
  for_each       = var.HA3 ? local.Subnets_definitions_H3 : local.Subnets_definitions
  subnet_id      = aws_subnet.Subnets[each.key].id
  route_table_id = aws_route_table.Routing_tables[each.key].id
}
