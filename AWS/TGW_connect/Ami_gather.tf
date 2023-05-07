resource "null_resource" "get_AMIs" {
  provisioner "local-exec" {
    command = "python3 /home/ec2-user/Terraform/Ami_gather.py"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
