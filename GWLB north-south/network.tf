
## VPCs ##

resource "aws_vpc" "VPCs" {
  for_each   = var.vpc_network_definitions
  cidr_block = var.vpc_network_definitions[each.key]["cidr_vpc_block"]
  tags       = merge(local.tags, { "Name" = "${each.key}" })
}

## subnets ##

resource "aws_subnet" "subnets" {
  for_each          = local.subnets_definitions_mapped
  vpc_id            = aws_vpc.VPCs[local.subnets_definitions_mapped[each.key]["vpc"]].id
  cidr_block        = local.subnets_definitions_mapped[each.key]["cidr_subnet_block"]
  availability_zone = data.aws_availability_zones.available.names[local.subnets_definitions_mapped[each.key]["available_zone"]]
  tags              = merge(local.tags, { "Name" = "${each.key}" })
}

## Security groups ##

resource "aws_security_group" "default" {
  for_each    = var.vpc_network_definitions
  name        = "Global-sg"
  description = "Global-sg"
  vpc_id      = aws_vpc.VPCs[each.key].id

  dynamic "ingress" {
    for_each = local.SG_ingress

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.SG_egress

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(local.tags, { "Name" = "Universal-SG" })
}

##### interfaces ####
resource "aws_network_interface" "Interfaces" {
  for_each          = local.interfaces_definitions
  subnet_id         = aws_subnet.subnets[local.interfaces_definitions[each.key]["subnet_name"]].id
  source_dest_check = local.interfaces_definitions[each.key]["security_role"] == "true" && local.interfaces_definitions[each.key]["subnet_role"] == "Private" ? false : true
  description       = each.key
  tags              = merge(local.tags, { "Name" = "${each.key}" })
  security_groups   = [aws_security_group.default[local.interfaces_definitions[each.key]["vpc"]].id]
}

### GWLB ###

resource "aws_lb" "gwlb" {
  name                       = "GWLB"
  internal                   = false
  load_balancer_type         = "gateway"
  enable_deletion_protection = false

  dynamic "subnet_mapping" {
    for_each = local.subnet_gwlb_names

    content {
      subnet_id = aws_subnet.subnets[subnet_mapping.key].id
      #private_ipv4_address = cidrhost(aws_subnet.subnets[subnet_mapping.key].cidr_block, 100)
    }
  }

  tags = merge(local.tags, { "Name" = "GWLB" })
}

resource "aws_lb_target_group" "target_grup_north_south" {
  name        = "tg-GENEVE"
  protocol    = "GENEVE"
  port        = 6081
  target_type = "ip"
  vpc_id      = aws_vpc.VPCs["Secure_VPC"].id

  health_check {
    port     = 1080
    protocol = "TCP"
    timeout  = 5
    interval = 10
  }
}

resource "aws_lb_listener" "listener_north_south" {
  load_balancer_arn = aws_lb.gwlb.arn

  default_action {
    target_group_arn = aws_lb_target_group.target_grup_north_south.arn
    type             = "forward"
  }

}

resource "aws_lb_target_group_attachment" "target_grup_north_south_attachment" {
  for_each         = local.fgt_private_interfaces
  target_group_arn = aws_lb_target_group.target_grup_north_south.arn
  target_id        = aws_network_interface.Interfaces[local.fgt_private_interfaces[each.key]["Private_interface"]].private_ip
  port             = 6081
}

data "aws_caller_identity" "current" {}

resource "aws_vpc_endpoint_service" "endpoint_service" {
  acceptance_required        = false
  allowed_principals         = [data.aws_caller_identity.current.arn]
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
}

resource "aws_vpc_endpoint" "endpoint" {
  for_each          = local.subnet_endpoint_names
  service_name      = aws_vpc_endpoint_service.endpoint_service.service_name
  subnet_ids        = [aws_subnet.subnets[local.subnet_endpoint_names[each.key]["subnet"]].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.endpoint_service.service_type
  vpc_id            = aws_vpc.VPCs[local.subnet_endpoint_names[each.key]["vpc"]].id
  tags              = merge(local.tags, { "Name" = "${each.key}" })
}

### internet gateway ###

resource "aws_internet_gateway" "gw" {
  for_each = var.vpc_network_definitions
  vpc_id   = aws_vpc.VPCs[each.key].id
  tags     = merge(local.tags, { "Name" = "${each.key} internet gateway" })
}

## EIP

resource "aws_eip" "linux_eips" {
  for_each                  = local.linux_private_interfaces
  vpc                       = true
  network_interface         = aws_network_interface.Interfaces[each.key].id
  associate_with_private_ip = aws_network_interface.Interfaces[each.key].private_ip
}

resource "aws_eip" "fgt_eips" {
  for_each                  = local.fgt_public_interfaces
  vpc                       = true
  network_interface         = aws_network_interface.Interfaces[local.fgt_public_interfaces[each.key]["Public_interface"]].id
  associate_with_private_ip = aws_network_interface.Interfaces[local.fgt_public_interfaces[each.key]["Public_interface"]].private_ip
}

### Routing tables ###

resource "aws_route_table" "To_internet_routes" {
  for_each = var.vpc_network_definitions
  vpc_id   = aws_vpc.VPCs[each.key].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[each.key].id
  }
  tags = merge(local.tags, { "Name" = "To_internet ${each.key} rt" })
}

resource "aws_route_table" "Private_FGT_rt" {
  for_each = local.fgt_private_interfaces
  vpc_id   = aws_vpc.VPCs[local.interfaces_definitions[local.fgt_private_interfaces[each.key]["Private_interface"]]["vpc"]].id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.Interfaces[local.fgt_private_interfaces[each.key]["Private_interface"]].id
  }
  tags = merge(local.tags, { "Name" = "Private subnet ${each.key} rt" })
}

resource "aws_route_table_association" "Private_FGT_rt_association" {
  for_each       = local.fgt_private_interfaces
  route_table_id = aws_route_table.Private_FGT_rt[each.key].id
  subnet_id      = aws_subnet.subnets[local.interfaces_definitions[local.fgt_private_interfaces[each.key]["Private_interface"]]["subnet_name"]].id
}

resource "aws_route_table_association" "To_internet_routes_associations" {
  for_each       = local.subnets_definitions_mapped_public
  route_table_id = aws_route_table.To_internet_routes[local.subnets_definitions_mapped_public[each.key]["vpc"]].id
  subnet_id      = aws_subnet.subnets[each.key].id
}

resource "aws_default_route_table" "Ingress_routes" {
  for_each               = local.subnet_endpoint_names
  default_route_table_id = aws_vpc.VPCs[local.subnet_endpoint_names[each.key]["vpc"]].default_route_table_id
  route {
    cidr_block      = local.subnets_definitions_mapped_private[index(keys(local.subnet_endpoint_names), each.key)]
    vpc_endpoint_id = aws_vpc_endpoint.endpoint[each.key].id
  }
  tags = merge(local.tags, { "Name" = "Ingres route ${each.key}" })
}

resource "aws_vpc_endpoint_route_table_association" "Ingress_routes_vpce_associations" {
  for_each = local.subnet_endpoint_names
  route_table_id  = aws_vpc.VPCs[local.subnet_endpoint_names[each.key]["vpc"]].default_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint[each.key].id
}

resource "aws_route_table_association" "Ingress_routes_gw" {
  for_each = var.vpc_network_definitions 
  route_table_id = aws_vpc.VPCs[each.key].default_route_table_id
  gateway_id = aws_internet_gateway.gw[each.key].id
}

resource "aws_route_table" "Private_rt" {
  for_each = local.subnet_endpoint_names
  vpc_id   = aws_vpc.VPCs[local.subnet_endpoint_names[each.key]["vpc"]].id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.endpoint[each.key].id
  }
  tags = merge(local.tags, { "Name" = "Private route ${each.key}" })
}

resource "aws_route_table_association" "Private_rt_associations" {
  for_each       = local.subnet_private_names
  route_table_id = aws_route_table.Private_rt[each.key].id
  subnet_id      = aws_subnet.subnets[local.subnet_private_names[each.key]["subnet"]].id
}

