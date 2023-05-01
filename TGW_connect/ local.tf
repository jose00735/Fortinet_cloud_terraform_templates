locals {
    tags = {
        "Deploy" = "TGW"
        "Project" = "TF"
    }
    Global_ingress_rules = [
        {
            from_port = 0
            to_port = 0
            protocol = "icmp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 10443
            to_port = 10443
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 8080
            to_port = 8090
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 2222
            to_port = 22232
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 0
            to_port = 0
            protocol = "47"
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]
    Global_egress_rules = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]
    AMIs_data = jsondecode(file("/home/ec2-user/Terraform/Amis.json"))
    transit_gateway_address = "10.0.254.10"
    local-as-bgp = "64513"
    transit_gateway_connect_cidr_blocks = ["169.254.254."]
    remote-as-bgp = "64512"
}

locals {
    AMI = join("", [for item in local.AMIs_data: item.Architecture == var.arch && item.Version == var.ver && item.License == var.license ? item.ImageId : ""])
    Apache_Clients_ip = [for apache_servers_ip in aws_network_interface.client-interfaces: apache_servers_ip.private_ip]   
    Indexed_Apache_Clients_ip = [ 
        for i, item in local.Apache_Clients_ip: 
        { 
            index = i
            ip = item
        } 
    ]
    filtered_fgt_interface_definitions = { for k, v in var.fgt_interface_definitions: k => v if k != "TGW" }
    apache_http_ports = [for client in keys(var.Clients_definitions): "http to ${client}: http://${aws_eip.FGT_EIP[0].public_ip}:${8080 + index(keys(var.Clients_definitions), client)}"]
    apache_ssh_ports = [for client in keys(var.Clients_definitions): "ssh -i /home/ec2-user/.ssh/id_rsa ec2-user@${aws_eip.FGT_EIP[0].public_ip} -p ${2222 + index(keys(var.Clients_definitions), client)}"]
}
