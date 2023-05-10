resource "aws_key_pair" "key_LB" {
  key_name   = "key_LB"
  public_key = file("/home/ec2-user/.ssh/id_rsa.pub")
}

module "fortigates" {
  source           = "./modules/FGT"
  for_each         = local.fgt_roles
  admin-user       = var.admin-user
  password         = var.password
  key_name         = aws_key_pair.key_LB.key_name
  interfaces       = local.fgt_interfaces
  role             = each.value
  fortigate_name = each.key
  HA3 = var.HA3
  license_file = "${local.license_files}"
  private_linux_ip = local.linux_ip[each.key]["instance_IP"]
  tags             = local.tags
  arch             = var.arch
  ver              = var.ver
  license_type           = "${var.license}"
  ha_peer_ip = local.ha_peer_ip
  IAM_profile = aws_iam_instance_profile.FGT_HA_Profile.name
  vpc_cidr_block = aws_vpc.HA-A-P.cidr_block
  private_gw = local.linux_ip[each.key]["gateway_IP"]
}

module "apache" {
  source               = "./modules/Linux"
  for_each             = local.Private_subnets
  client_number        = each.key
  key_name             = aws_key_pair.key_LB.key_name
  private_interface_id = aws_network_interface.Linux_Interfaces[each.key].id
  tags                 = local.tags
}

resource "aws_iam_policy" "FGT_HA_Policy" {
  name        = "FGT_HA_Policy"
  path        = "/"
  description = "permissions to allow fortigate do HA"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = "*"
        Action = [
          "ec2:Describe*",
          "ec2:AssociateAddress",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:ReplaceRoute",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "inspector:DescribeFindings",
          "inspector:ListFindings",
          "s3:GetObject"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "FGT_HA_Role" {
  name = "FGT_HA_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.FGT_HA_Policy.arn]
}


resource "aws_iam_instance_profile" "FGT_HA_Profile" {
  name = "FGT_HA_Profile"
  role = aws_iam_role.FGT_HA_Role.name
}
