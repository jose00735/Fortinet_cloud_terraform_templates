resource "aws_instance" "fastapi1" {
    ami = "ami-009c5f630e96948cb"
    instance_type = "t2.small"
    key_name = var.key_name
    user_data = file(var.bootstrap)
    network_interface {
      network_interface_id = aws_network_interface.fastapi_interface.id
      device_index = 0
    }
}

resource "aws_network_interface" "fastapi_interface" {
  subnet_id       = var.subnet
  security_groups = var.security_group
}
