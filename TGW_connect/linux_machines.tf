### Servers ###

module "apache_servers" {
    source = "./modules/apache"
    for_each = var.Clients_definitions
    bootstrap = var.bootstrap
    key_name = aws_key_pair.key_LB.key_name
    interface_id = aws_network_interface.client-interfaces[each.key].id
    client_number = each.key
}