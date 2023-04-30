resource "aws_instance" "fastapi1" {
    ami = "ami-009c5f630e96948cb"
    instance_type = "t2.small"
    key_name = aws_key_pair.key_LB.key_name
    user_data = file("${path.module}/bootstrap.sh")
    network_interface {
      network_interface_id = aws_network_interface.fastapi1_interface.id
      device_index = 0
    }
}

resource "aws_network_interface" "fastapi1_interface" {
  subnet_id       = aws_subnet.private_subnet_1.id
  security_groups = [ aws_security_group.FGT.id ]
}

resource "aws_instance" "fastapi2" {
    ami = "ami-009c5f630e96948cb"
    instance_type = "t2.small"
    key_name = aws_key_pair.key_LB.key_name
    user_data = file("${path.module}/bootstrap.sh")
    network_interface {
      network_interface_id = aws_network_interface.fastapi2_interface.id
      device_index = 0
    }
}

resource "aws_network_interface" "fastapi2_interface" {
  subnet_id       = aws_subnet.private_subnet_2.id
  security_groups = [ aws_security_group.FGT.id ]
}