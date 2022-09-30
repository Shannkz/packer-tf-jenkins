output "jenkins_server_ami_name" {
    value = "${data.aws_ami.ubuntu.name}"
}

output "jenkins_server_ami_id" {
    value = "${data.aws_ami.ubuntu.id}"
}

output "jenkins_server_public_ip" {
    value = "${aws_instance.jenkins_server.public_ip}"
}

output "jenkins_server_private_ip" {
    value = "${aws_instance.jenkins_server.private_ip}"
}