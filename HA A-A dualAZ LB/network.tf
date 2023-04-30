##### VPC #####
resource "aws_vpc" "LBE_LBI" {
  cidr_block = "10.0.0.0/16"
  tags = merge(local.tags, {"Name" = "VPC"})
}

##### GW #####
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.LBE_LBI.id
}


#### DATA #####
data "aws_availability_zones" "available" {}
locals {
    tags = {
        "Deploy" = "LoadBalancer"
        "Project" = "TF"
    }
}

######### External and internal load balancer ########

resource "aws_lb" "External_LB" {
  name               = "ExternalLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = [ aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  enable_deletion_protection = false
  tags = merge(local.tags, {"Name" = "LB"})
}

resource "aws_security_group" "External_LB_SG" {
  name        = "loadbalancer-sg"
  description = "Load balancer security group"
  vpc_id      = aws_vpc.LBE_LBI.id

  dynamic "ingress" {
    for_each = local.LB_ingress_rules

    content {
        from_port = ingress.value.from_port
        to_port = ingress.value.to_port
        protocol = ingress.value.protocol
        cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.LBE_LBI.cidr_block]
  }

  tags = merge(local.tags, { "Name" = "loadbalancer-sg" })
}

resource "aws_lb_target_group" "target_group" {
  count = length(var.listener_ports)
  name     = "target-group${var.listener_ports[count.index]}"
  port     = var.listener_ports[count.index]
  protocol = "TCP"
  vpc_id   = aws_vpc.LBE_LBI.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 5
    port                = 1080
    protocol            = "TCP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.tags, { "Name" = "target-group" })
}

resource "aws_lb_listener" "lb_listener" {
    count = length(var.listener_ports)
    load_balancer_arn = aws_lb.External_LB.arn
    port = var.listener_ports[count.index]
    protocol = "TCP"

    default_action {
        type = "forward"
        target_group_arn = element(aws_lb_target_group.target_group.*.arn, count.index)
    }
}

resource "aws_lb_target_group_attachment" "lb_listener_attachment_fgt1" {
  count = length(var.listener_ports)
  target_group_arn = element(aws_lb_target_group.target_group.*.arn, count.index)
  target_id        = aws_network_interface.fgt1_public_interface.private_ip
  port             = var.listener_ports[count.index]
}

resource "aws_lb_target_group_attachment" "lb_listener_attachment_fgt2" {
  count = length(var.listener_ports)
  target_group_arn = element(aws_lb_target_group.target_group.*.arn, count.index)
  target_id        = aws_network_interface.fgt2_public_interface.private_ip
  port             = var.listener_ports[count.index]
}

######### FGT1 area #########

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.LBE_LBI.id 
    cidr_block = "10.0.0.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = merge(local.tags, {"Area" = "FGT1"})
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.LBE_LBI.id 
    cidr_block = "10.0.1.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = merge(local.tags, {"Area" = "FGT1"})
}

resource "aws_subnet" "management_subnet_1" {
    vpc_id = aws_vpc.LBE_LBI.id 
    cidr_block = "10.0.2.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = merge(local.tags, {"Area" = "FGT1"})
}

resource "aws_network_interface" "fgt1_public_interface" {
    subnet_id = aws_subnet.public_subnet_1.id
    description = "external interface of the fortigate 1"
    tags = merge(local.tags, {"Area" = "FGT1"})
    security_groups = [ aws_security_group.FGT.id ]
}

resource "aws_network_interface" "fgt1_private_interface" {
    subnet_id = aws_subnet.private_subnet_1.id
    description = "internal interface of the fortigate 2"
    security_groups = [ aws_security_group.FGT.id ]
    source_dest_check = false
    tags = merge(local.tags, {"Area" = "FGT1"})
}

resource "aws_network_interface" "fgt1_management_interface" {
    subnet_id = aws_subnet.management_subnet_1.id
    description = "mgmt interface of the fortigate 2"
    security_groups = [ aws_security_group.FGT.id ]
    tags = merge(local.tags, {"Area" = "FGT1"})
}

######### FGT2 area #########

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.LBE_LBI.id 
    cidr_block = "10.0.3.0/24"
    availability_zone = data.aws_availability_zones.available.names[2]
    tags = merge(local.tags, {"Area" = "FGT2"})
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.LBE_LBI.id 
    cidr_block = "10.0.4.0/24"
    availability_zone = data.aws_availability_zones.available.names[2]
    tags = merge(local.tags, {"Area" = "FGT2"})
}

resource "aws_network_interface" "fgt2_public_interface" {
    subnet_id = aws_subnet.public_subnet_2.id
    description = "external interface of the fortigate 2"
    security_groups = [ aws_security_group.FGT.id ]
    tags = merge(local.tags, {"Area" = "FGT2"})
}

resource "aws_network_interface" "fgt2_private_interface" {
    subnet_id = aws_subnet.private_subnet_2.id
    description = "internal interface of the fortigate 2"
    security_groups = [ aws_security_group.FGT.id ]
    source_dest_check = false
    tags = merge(local.tags, {"Area" = "FGT2"})
}

resource "aws_security_group" "FGT" {
  name        = "FGT-sg"
  description = "FGT security group"
  vpc_id      = aws_vpc.LBE_LBI.id

  dynamic "ingress" {
    for_each = local.FGT_ingress_rules

    content {
        from_port = ingress.value.from_port
        to_port = ingress.value.to_port
        protocol = ingress.value.protocol
        cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { "Name" = "FGT-sg" })
}

##### routing tables ####

resource "aws_route_table" "public_rt_1" {
    vpc_id = aws_vpc.LBE_LBI.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_route_table_association" "public_rt_1_association"{
    route_table_id = aws_route_table.public_rt_1.id
    subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table" "private_rt_1" {
    vpc_id = aws_vpc.LBE_LBI.id

    route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = aws_network_interface.fgt1_private_interface.id
    }
    route {
        cidr_block = aws_subnet.public_subnet_1.cidr_block
        network_interface_id = aws_network_interface.fgt1_private_interface.id
    }
}

resource "aws_route_table_association" "private_rt_1"{
    route_table_id = aws_route_table.private_rt_1.id
    subnet_id = aws_subnet.private_subnet_1.id
}

resource "aws_route_table" "public_rt_2" {
    vpc_id = aws_vpc.LBE_LBI.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_route_table_association" "public_rt_2_association"{
    route_table_id = aws_route_table.public_rt_2.id
    subnet_id = aws_subnet.public_subnet_2.id
}


resource "aws_route_table" "private_rt_2" {
    vpc_id = aws_vpc.LBE_LBI.id

    route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = aws_network_interface.fgt2_private_interface.id
    }
    route {
        cidr_block = aws_subnet.public_subnet_2.cidr_block
        network_interface_id = aws_network_interface.fgt2_private_interface.id
    }
}

resource "aws_route_table_association" "private_rt_2"{
    route_table_id = aws_route_table.private_rt_2.id
    subnet_id = aws_subnet.private_subnet_2.id
}

resource "aws_eip" "FGT1_EIP" {
  depends_on = [ aws_instance.FGT1, aws_internet_gateway.gw ]
  vpc = true
  network_interface = aws_network_interface.fgt1_public_interface.id
  associate_with_private_ip = aws_network_interface.fgt1_public_interface.private_ip
}

resource "aws_eip" "FGT2_EIP" {
  depends_on = [ aws_instance.FGT1, aws_internet_gateway.gw ]  
  vpc = true
  network_interface = aws_network_interface.fgt2_public_interface.id
  associate_with_private_ip = aws_network_interface.fgt2_public_interface.private_ip
}