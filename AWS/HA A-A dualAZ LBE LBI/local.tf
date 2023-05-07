locals {
    tags = {
        "Deploy" = "LoadBalancer"
        "Project" = "TF"
    }
    FGT_ingress_rules = [
    {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 2222
        to_port     = 2222
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 2223
        to_port     = 2223
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 10443
        to_port     = 10443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 1080
        to_port     = 1080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ]
    AMIs_data = jsondecode(file("/home/ec2-user/Terraform/Amis.json"))
}

locals {
    AMI = join("", [for item in local.AMIs_data: item.Architecture == var.arch && item.Version == var.ver && item.License == var.license ? item.ImageId : ""])
}

