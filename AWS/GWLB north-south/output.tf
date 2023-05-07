output "FGT_EIP" {
  value = [for public_ips in aws_eip.fgt_eips : "https://${public_ips.public_ip}:10443"]
}

output "Linux_EIP" {
  value = [for public_ips in aws_eip.linux_eips : "http://${public_ips.public_ip}:80"]
}