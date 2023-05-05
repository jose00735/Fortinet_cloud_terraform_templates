resource "aws_instance" "FGT" {
  depends_on    = [null_resource.get_AMIs]
  ami           = local.AMI
  key_name      = var.key_name
  instance_type = "c6i.xlarge"
  user_data = templatefile("${path.module}/fgt.conf", {
    admin-user                = "${var.admin-user}",
    password                  = "${var.password}",
    private_subnet_address = var.private_subnet_address,
    GWLB_interface_ip = "${var.GWLB_interface_ip}"
  })

  network_interface {
    network_interface_id = var.public_interface_id
    device_index = 0 
  }

  network_interface {
    network_interface_id = var.private_interface_id
    device_index = 1
  }
  
  tags = merge(var.tags, { "Name" = "Fortigate of Secure VPC" })
}

