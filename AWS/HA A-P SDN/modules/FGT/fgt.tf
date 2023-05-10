resource "aws_instance" "FGT" {
  depends_on    = [null_resource.get_AMIs]
  ami           = local.AMI
  key_name      = var.key_name
  instance_type = "c6i.xlarge"
  iam_instance_profile = var.IAM_profile
  user_data = templatefile("${local.fgt_config}", {
    admin-user                = "${var.admin-user}",
    password                  = "${var.password}",
    private_linux_ip = "${var.private_linux_ip}",
    peer_ha_ip = "${var.ha_peer_ip[var.fortigate_name]["ha_peer_ip"]}"
    ha_ip = "${var.ha_peer_ip[var.fortigate_name]["ha_ip"]}"
    mgmt_gateway_ip = "${var.ha_peer_ip[var.fortigate_name]["mgmt_gw"]}"
    license_file = "${var.license_file[var.fortigate_name]}"
    license_type = "${var.license_type}"
    vpc_cidr_block = "${var.vpc_cidr_block}"
    private_gw = var.private_gw
  })

  dynamic "network_interface" {
    for_each = var.interfaces[var.fortigate_name]
    content {
      network_interface_id = network_interface.value["id"]
      device_index = network_interface.value["index"]
  } 
}
  tags = merge(var.tags, { "Name" = "Fortigate ${var.role}" })
}

