resource "aws_instance" "apache_instance" {
    ami = "ami-009c5f630e96948cb"
    instance_type = "t2.small"
    key_name = var.key_name
    user_data = templatefile(var.bootstrap, {
      client_number = "${var.client_number}"
    })
    network_interface {
      network_interface_id = var.interface_id
      device_index = 0
    }
    tags = {
      "Name" = "Client ${var.client_number}"
    }
}
