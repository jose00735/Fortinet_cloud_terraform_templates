##### VPC #####
resource "aws_vpc" "Secure_vpc" {
  cidr_block = "10.0.0.0/24"
  tags = merge(local.tags, {"Name" = "Secure_vpc"})
}

resource "aws_vpc" "Clients" {
  for_each = var.Clients_definitions
  cidr_block = join("/",[var.Clients_definitions[each.key]["network_address"],tostring(var.Clients_definitions[each.key]["subnet_mask"])])
  tags = merge(local.tags, {"Name" = "${each.key} VPC"})
}

#### AZ availables #####

data "aws_availability_zones" "available" {}

##### GW #####
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.Secure_vpc.id
}

### Security Groups ###

resource "aws_security_group" "FGT-sg" {
  name        = "FGT-sg"
  description = "FGT security group"
  vpc_id      = aws_vpc.Secure_vpc.id

  dynamic "ingress" {
    for_each = local.Global_ingress_rules

    content {
        from_port = ingress.value.from_port
        to_port = ingress.value.to_port
        protocol = ingress.value.protocol
        cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.Global_egress_rules

    content {
        from_port = egress.value.from_port
        to_port = egress.value.to_port
        protocol = egress.value.protocol
        cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(local.tags, { "Name" = "FGT-sg" })
}

resource "aws_security_group" "Client-SG" {
  for_each = var.Clients_definitions
  name        = "Client-SG"
  description = "Client security group"
  vpc_id      = aws_vpc.Clients[each.key].id

  ingress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
  }

  egress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
  }
    tags = merge(local.tags, { "Name" = "${each.key} Security group" })

}

##### interfaces ####

resource "aws_subnet" "FGT-subnets" {
    for_each = var.fgt_interface_definitions
    vpc_id = aws_vpc.Secure_vpc.id 
    cidr_block = each.value
    tags = merge(local.tags, {"Area" = "FGT", "Name" = "${each.key} Subnet"})
    availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "client-subnets" {
    for_each = var.Clients_definitions
    vpc_id = aws_vpc.Clients[each.key].id 
    cidr_block = join("/",[var.Clients_definitions[each.key]["network_address"],tostring(var.Clients_definitions[each.key]["subnet_mask"] + 1)])
    tags = merge(local.tags, {"Area" = "FGT", "Name" = "${each.key} Subnet"})
    availability_zone = data.aws_availability_zones.available.names[index(keys(var.Clients_definitions), each.key)]
}

resource "aws_network_interface" "FGT-interfaces" {
    for_each = local.filtered_fgt_interface_definitions #it is filtered to avoid creating a interface for TGW
    subnet_id = aws_subnet.FGT-subnets[each.key].id
    source_dest_check = each.key == "private" ? false : true 
    description = "${each.key} interface of the fortigate"
    tags = merge(local.tags, {"Area" = "FGT", "Name" = "${each.key} interface of the fortigate"})
    security_groups = [ aws_security_group.FGT-sg.id ]
}

resource "aws_network_interface" "client-interfaces" {
    for_each = var.Clients_definitions
    subnet_id = aws_subnet.client-subnets[each.key].id
    description = "${each.key} interface"
    tags = merge(local.tags, {"Area" = "${each.key}", "Name" = "${each.key} interface"})
    security_groups = [ aws_security_group.Client-SG[each.key].id ]
}

##### routing tables ####

resource "aws_route_table" "fortigate_routing_tables" {
    for_each = local.filtered_fgt_interface_definitions
    vpc_id = aws_vpc.Secure_vpc.id
    
    dynamic "route" {
        for_each = merge(var.Clients_definitions, var.TGW_Cidr_definition)
        content {
          cidr_block = join("/",[merge(var.Clients_definitions, var.TGW_Cidr_definition)[route.key]["network_address"],tostring(merge(var.Clients_definitions, var.TGW_Cidr_definition)[route.key]["subnet_mask"])])
          transit_gateway_id = aws_ec2_transit_gateway.TGW.id
        }
    }

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = each.key == "public" ? aws_internet_gateway.gw.id : ""
      network_interface_id = each.key == "public" ? "" : aws_network_interface.FGT-interfaces[each.key].id
    }
    
    tags = merge(local.tags, {"Area" = "FGT", "Name" = "${each.key} routing table"})
}

resource "aws_route_table_association" "fortigate_routing_tables_association"{
    for_each = local.filtered_fgt_interface_definitions
    route_table_id = aws_route_table.fortigate_routing_tables[each.key].id
    subnet_id = aws_subnet.FGT-subnets[each.key].id
}

resource "aws_route_table" "clients_routing_table" {
    for_each = var.Clients_definitions 
    vpc_id = aws_vpc.Clients[each.key].id
  
    route {
      cidr_block = "0.0.0.0/0"
      transit_gateway_id = aws_ec2_transit_gateway.TGW.id
    }
    
    tags = merge(local.tags, {"Area" = "${each.key}", "Name" = "${each.key} routing table"})
}

resource "aws_route_table_association" "clients_routing_table_association"{
    for_each = var.Clients_definitions
    route_table_id = aws_route_table.clients_routing_table[each.key].id
    subnet_id = aws_subnet.client-subnets[each.key].id
}

#### EIP declaration ####

resource "aws_eip" "FGT_EIP" {
  count = sum([for interface in keys(local.filtered_fgt_interface_definitions): interface == "public" ? 1 : 0])
  depends_on = [ aws_instance.FGT ]
  vpc = true 
  network_interface = aws_network_interface.FGT-interfaces["public"].id
  associate_with_private_ip = aws_network_interface.FGT-interfaces["public"].private_ip
}

#### Transit gateway ###

resource "aws_ec2_transit_gateway" "TGW" {
  description = "My Transit Gateway"
  tags = merge(local.tags, {"Name" = "TGW"})
  transit_gateway_cidr_blocks = [join("/",[var.TGW_Cidr_definition["TGW"]["network_address"], var.TGW_Cidr_definition["TGW"]["subnet_mask"]])]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "secure_vpc_attach" {
  subnet_ids             = [aws_subnet.FGT-subnets["TGW"].id]
  transit_gateway_id    = aws_ec2_transit_gateway.TGW.id
  vpc_id                = aws_vpc.Secure_vpc.id
  tags = merge(local.tags, {"Name" = "Secure VPC TGW attach"})
}

resource "aws_ec2_transit_gateway_vpc_attachment" "clients_vpc_attach" {
  for_each = var.Clients_definitions
  subnet_ids             = [aws_subnet.client-subnets[each.key].id]
  transit_gateway_id    = aws_ec2_transit_gateway.TGW.id
  vpc_id                = aws_vpc.Clients[each.key].id
  tags = merge(local.tags, {"Name" = "${each.key} VPC TGW attach"})
}

resource "aws_ec2_transit_gateway_connect" "connect" {
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.secure_vpc_attach.id
  transit_gateway_id      = aws_ec2_transit_gateway.TGW.id
  tags = merge(local.tags, {"Name" = "Connect"})
}

resource "aws_ec2_transit_gateway_connect_peer" "example" {
  peer_address                  = aws_network_interface.FGT-interfaces["private"].private_ip
  inside_cidr_blocks            = [join("0/",[local.transit_gateway_connect_cidr_blocks[0], "29"])]
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect.id
  bgp_asn = local.local-as-bgp
  transit_gateway_address = local.transit_gateway_address
  tags = merge(local.tags, {"Name" = "Connect Peer"})
}