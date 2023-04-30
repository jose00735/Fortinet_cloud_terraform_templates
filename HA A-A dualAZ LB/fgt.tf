resource "aws_key_pair" "key_LB" {
  key_name   = "key_LB"
  public_key = file("/home/ec2-user/.ssh/id_rsa.pub")
}

resource "aws_instance" "FGT1" {
    depends_on = [ null_resource.get_AMIs ]
    ami = local.AMI
    key_name = aws_key_pair.key_LB.key_name
    instance_type = "c6i.xlarge"
    user_data = templatefile("${path.module}/fgt_primary.conf", {
        fortigate2_private_ip = "${aws_network_interface.fgt2_public_interface.private_ip}",
        fortigate1_public_ip = "${aws_network_interface.fgt1_public_interface.private_ip}",
        fastapi1 = "${aws_network_interface.fastapi1_interface.private_ip}"
    })
    network_interface {
        network_interface_id = aws_network_interface.fgt1_public_interface.id
        device_index = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.fgt1_private_interface.id
        device_index = 1
    }
}

resource "aws_instance" "FGT2" {
    depends_on = [ null_resource.get_AMIs ]
    ami = local.AMI
    key_name = aws_key_pair.key_LB.key_name
    instance_type = "c6i.xlarge"
    user_data = templatefile("${path.module}/fgt_secondary.conf", {
        fortigate2_public_ip = "${aws_network_interface.fgt2_public_interface.private_ip}",
        fortigate1_private_ip = "${aws_network_interface.fgt1_private_interface.private_ip}",
        fastapi2 = "${aws_network_interface.fastapi2_interface.private_ip}"
    })
    network_interface {
        network_interface_id = aws_network_interface.fgt2_public_interface.id
        device_index = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.fgt2_private_interface.id
        device_index = 1
    }
}