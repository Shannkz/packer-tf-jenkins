resource "aws_security_group" "worker_windows" {
  name        = "worker_windows"
  description = "Jenkins Server: created by Terraform for [dev]"

  # legacy name of VPC ID
  vpc_id = aws_vpc.worker_vpc.id

  tags = {
    Name = "worker_windows"
    env  = "dev"
  }
}

###############################################################################
# ALL INBOUND
###############################################################################

# ssh
resource "aws_security_group_rule" "jenkins_worker_windows_from_source_ingress_webui" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "ssh to jenkins_worker_windows"
}

# rdp
resource "aws_security_group_rule" "jenkins_worker_windows_from_rdp" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["82.78.232.79/32"]
  description       = "rdp to jenkins_worker_windows"
}

###############################################################################
# ALL OUTBOUND
###############################################################################

resource "aws_security_group_rule" "jenkins_worker_windows_to_all_80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow jenkins worker to all 80"
}

resource "aws_security_group_rule" "jenkins_worker_windows_to_all_443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow jenkins worker to all 443"
}

resource "aws_security_group_rule" "jenkins_worker_windows_to_jenkins_server_33453" {
  type              = "egress"
  from_port         = 33453
  to_port           = 33453
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow jenkins worker windows to jenkins server"
}

resource "aws_security_group_rule" "jenkins_worker_windows_to_jenkins_server_8080" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.worker_windows.id}"
  # source_security_group_id = "${aws_security_group.jenkins_server.id}"
  cidr_blocks              = ["0.0.0.0/0"]
  description              = "allow jenkins workers windows to jenkins server"
}

resource "aws_security_group_rule" "jenkins_worker_windows_to_all_22" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker_windows.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow jenkins worker windows to connect outbound from 22"
}
