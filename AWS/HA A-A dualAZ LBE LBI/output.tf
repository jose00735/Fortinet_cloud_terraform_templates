output "management_fgt1" {
    value = "Management FGT1 ${aws_eip.FGT1_EIP.public_ip}"
}

output "instance_id_FGT1" {
    value = "Management FGT1 ${aws_instance.FGT1.id}"
}

output "management_fgt2" {
    value = "Management FGT2 ${aws_eip.FGT2_EIP.public_ip}"
}

output "instance_id_FGT2" {
    value = "Management FGT2 ${aws_instance.FGT2.id}"
}

output "External_loadbalancer_dns" {
    value = "External loadbalancer dns ${aws_lb.External_LB.dns_name}"
}

output "Internal_loadbalancer_dns" {
    value = "Internal loadbalancer dns ${aws_lb.Internal_LB.dns_name}"
}