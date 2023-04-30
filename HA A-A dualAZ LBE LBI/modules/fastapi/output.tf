output "private_ip" {
    value = aws_network_interface.fastapi_interface.private_ip
}