resource "aws_key_pair" "jenkins_worker_windows" {
  key_name   = "jenkins_worker_windows"
  public_key = "${file("${path.module}/jenkins_worker.pub")}"
}

// Get local file for content
data "local_file" "jenkins_worker_pem" {
  filename = "${path.module}/jenkins_worker.pem"
}

# Fetch from AWS API most recent Amazon Linux 20.04 image
data "aws_ami" "windows_server" {
    most_recent = "true"

    filter {
      name = "name"
      values = ["Windows_Server-2019-English-Full-Containers*"]
    }

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }

    filter {
      name = "root-device-type"
      values = ["ebs"]
    }

    # owners = ["801119661308"]
}

# data "cloudinit_config" "windows" {
#   gzip = false
#   base64_encode = false

#   part {
#     content_type = "text/x-shellscript"
#     filename = "SetUpWinRM.ps1"
#     content = file("${path.module}/scripts/SetUpWinRM.ps1")
#   }

#   part {
#     content_type = "text/x-shellscript"
#     filename = "disable-uac.ps1"
#     content = file("${path.module}/scripts/disable-uac.ps1")
#   }

#   part {
#     content_type = "text/x-shellscript"
#     filename = "enable-rdp.ps1"
#     content = file("${path.module}/scripts/enable-rdp.ps1")
#   }

#   part {
#     content_type = "text/x-shellscript"
#     filename = "install_windows.ps1"
#     content = file("${path.module}/scripts/install_windows.ps1")
#   }

#   part {
#     content_type = "text/x-shellscript"
#     filename = "jekins_worker_windows.ps1"
#     content = templatefile("${path.module}/scripts/jenkins_worker_windows.ps1", {
#       env         = "dev"
#       region      = "eu-central-1"
#       datacenter  = "dev-eu-central-1"
#       node_name   = "eu-central-1-jenkins_worker_windows"
#       domain      = ""
#       device_name = "eth0"
#       server_ip   = data.aws_instance.controller.private_ip
#       worker_pem  = "${data.local_file.jenkins_worker_pem.content}"
#       jenkins_username = "usr"
#       jenkins_password = "pwd"
#   })
#   }
# }

# lookup the security group of the Jenkins Server
data "aws_security_group" "jenkins_worker_windows" {
  filter {
    name   = "group-name"
    values = ["dev_jenkins_worker_windows"]
  }
}

resource "aws_instance" "windows_agent" {
  ami                         = data.aws_ami.windows_server.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.worker_windows.id}"]
  # name_prefix                 = "windows-worker"
  iam_instance_profile        = "dev_jenkins_worker_windows"
  key_name                    = aws_key_pair.jenkins_worker_windows.key_name
  security_groups             = ["${aws_security_group.worker_windows.id}"]
#   user_data                   = data.cloudinit_config.windows.rendered
  user_data                   = templatefile("scripts/prepare_agent.tpl", {
      env         = "dev"
      region      = "eu-central-1"
      datacenter  = "dev-eu-central-1"
      node_name   = "eu-central-1-jenkins_worker_windows"
      domain      = ""
      device_name = "eth0"
      server_ip   = data.aws_instance.controller.public_ip
      worker_pem  = "${data.local_file.jenkins_worker_pem.content}"
      jenkins_username = "usr"
      jenkins_password = "pwd"
  })
  subnet_id                   = aws_subnet.agent_public_subnet.id

  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size = 50
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "windows_agent"
  }
}
