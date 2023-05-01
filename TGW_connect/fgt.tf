resource "aws_key_pair" "key_LB" {
  key_name   = "key_LB"
  public_key = file("/home/ec2-user/.ssh/id_rsa.pub")
}

resource "aws_instance" "FGT" {
    depends_on = [ null_resource.get_AMIs, aws_network_interface.client-interfaces ]
    ami = local.AMI
    key_name = aws_key_pair.key_LB.key_name
    instance_type = "c6i.xlarge"
    user_data = templatefile("${path.module}/fgt.conf", {
        admin-user = "${var.admin-user}",
        password = "${var.password}",
        clients_apache_servers_ip = local.Indexed_Apache_Clients_ip,
        tgw_network_address = "${var.TGW_Cidr_definition["TGW"]["network_address"]}"
        tgw_subnet_mask = "${var.TGW_Cidr_definition["TGW"]["subnet_mask"]}"
        public_ip = "${aws_network_interface.FGT-interfaces["public"].private_ip}",
        remote-gw = "${local.transit_gateway_address}",
        local-gw = "${aws_network_interface.FGT-interfaces["private"].private_ip}",
        remote-bgp-as = "${local.remote-as-bgp}",
        local-bgp-as = "${local.local-as-bgp}",
        local_bgp_address = "${join("",[local.transit_gateway_connect_cidr_blocks[0],"1/32"])}",
        tgw-bgp1-address = "${join("",[local.transit_gateway_connect_cidr_blocks[0],"2"])}",
        tgw-bgp2-address = "${join("",[local.transit_gateway_connect_cidr_blocks[0],"3"])}",
        local_subnet = "${var.fgt_interface_definitions["private"]}"
    })

    dynamic "network_interface" {
        for_each = local.filtered_fgt_interface_definitions

        content {
            network_interface_id = aws_network_interface.FGT-interfaces[network_interface.key].id
            device_index = network_interface.key == "private" ? 1 : 0
        }
    }
    tags = merge(local.tags, {"Name" = "Fortigate of Secure VPC"})
}
