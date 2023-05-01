output "linux-ssh" {
    value = [for ssh in local.apache_ssh_ports: ssh]
}

output "linux-http" {
    value = [for http in local.apache_http_ports: http]
}

output "fgt-management-ip" {
    value = "FGT management ip ${aws_eip.FGT_EIP[0].public_ip}"
}

