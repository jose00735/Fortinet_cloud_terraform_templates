module "fastapi1" {
  source = "./modules/fastapi"
  subnet = aws_subnet.private_subnet_1.id
  security_group = [ aws_security_group.FGT.id ]
  bootstrap = var.bootstrap
  key_name = aws_key_pair.key_LB.key_name
}

module "fastapi2" {
  source = "./modules/fastapi"
  subnet = aws_subnet.private_subnet_2.id
  security_group = [ aws_security_group.FGT.id ]
  bootstrap = var.bootstrap
  key_name = aws_key_pair.key_LB.key_name
}
