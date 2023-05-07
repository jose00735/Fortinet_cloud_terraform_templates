##### Servers #####

module "fastapi1" {
  source = "./modules/fastapi"
  subnet = aws_subnet.private_subnet_1.id
  security_group = [ aws_security_group.FGT.id ]
  bootstrap = var.bootstrap1
  key_name = aws_key_pair.key_LB.key_name
}


module "fastapi2" {
  source = "./modules/fastapi"
  subnet = aws_subnet.private_subnet_2.id
  security_group = [ aws_security_group.FGT.id ]
  bootstrap = var.bootstrap2
  key_name = aws_key_pair.key_LB.key_name
}

##### Clients #####

module "client" {
  source = "./modules/fastapi"
  subnet = aws_subnet.private_subnet_1.id
  security_group = [ aws_security_group.FGT.id ]
  bootstrap = var.bootstrap_client
  key_name = aws_key_pair.key_LB.key_name
}
