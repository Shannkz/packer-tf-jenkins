# # AMI lookup for this Jenkins Server
# data "aws_ami" "jenkins_server" {
#   most_recent      = true
#   owners           = ["self"]

#   filter {
#     name   = "name"
#     values = ["amazon-linux-for-jenkins*"]
#   }
# }

# Fetch from AWS API most recent Amazon Linux 20.04 image
data "aws_ami" "ubuntu" {

  most_recent = "true"

  filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
      name = "virtualization-type"
      values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "jenkins_server" {
  key_name   = "jenkins_server"
  public_key = "${file("${path.module}/jenkins_server.pub")}"
}

# lookup the security group of the Jenkins Server
data "aws_security_group" "jenkins_server" {
  filter {
    name   = "group-name"
    values = ["jenkins_server"]
  }
}

# userdata for the Jenkins server ...
# data "template_file" "jenkins_server" {
#   template = "${file("scripts/jenkins_server.sh")}"

#   vars {
#     env = "dev"
#     jenkins_admin_password = "mysupersecretpassword"
#   }
# }

data "cloudinit_config" "linux" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    filename = "install_amazon.bash"
    content = file("${path.module}/scripts/install_amazon.bash")
  }

  part {
    content_type = "text/x-shellscript"
    filename = "jenkins_server.sh"
    content = file("${path.module}/scripts/jenkins_server.sh")
  }
}

# the Jenkins server itself
resource "aws_instance" "jenkins_server" {
  ami                    		= "${data.aws_ami.ubuntu.image_id}"
  instance_type          		= "t2.micro"
  key_name               		= "${aws_key_pair.jenkins_server.key_name}"
  subnet_id              		= "${data.aws_subnets.jenkins_public.ids[0]}"
  vpc_security_group_ids 		= ["${data.aws_security_group.jenkins_server.id}"]
  iam_instance_profile   		= "jenkins_server"
  # user_data              		= "${data.template_file.jenkins_server.rendered}"
  user_data              		= data.cloudinit_config.linux.rendered


  tags = {
    Name = "jenkins_server"
  }

  root_block_device {
    delete_on_termination = true
  }
}

# Creating an Elastic IP resource for the Jenkins server
# resource "aws_eip" "jenkins_eip" {
#     instance = aws_instance.jenkins_server.id
#     vpc = true

#     tags = {
#         Name = "jenkins_eip"
#     }
# }
