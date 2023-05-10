output "IPs" {
    value = [for names in local.EIPs_names : names ]
}