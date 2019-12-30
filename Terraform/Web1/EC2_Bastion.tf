resource "aws_eip" "bastion" {
  vpc = true
}

resource "aws_eip_association" "bastion" {
  network_interface_id = "${aws_network_interface.bastion.id}"
  allocation_id        = "${aws_eip.bastion.id}"
}

resource "aws_network_interface" "bastion" {
  depends_on = [aws_eip.bastion]
  subnet_id       = "${aws_subnet.Public.id}"
  security_groups = [
    "${aws_security_group.AwxAccessInSG.id}",
    "${aws_security_group.CommonManagementSG.id}"
  ]
}

resource "aws_instance" "bastion" {
  depends_on = [aws_network_interface.bastion]
  tags = {
    Name                 = "vm${var.modulename}bastion"
    OS                   = "ubuntu"
    Nebula_group_bastion = "true"
    Nebula_lighthouse    = "true"
    Nebula_ip            = "198.19.1.3/24"
    HasRoleBastion       = "true"
  }

  ami           = "${var.ami_ubuntu1804}"
  instance_type = "t2.nano"
  key_name      = "${aws_key_pair.service.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.bastion.id}"
    device_index         = 0
  }

  user_data = <<USERDATA
#! /bin/bash
hostnamectl set-hostname vm${var.modulename}bastion
USERDATA
}

resource "aws_security_group" "AwxAccessInSG" {
  name = "AwxAccessInSG"
  description = "Awx Access In security group"
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "AwxAccessInSG"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["${var.awx_public_ip}/32"]
  }
  egress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["${var.public_first_three_octets}.0/24","${var.private_first_three_octets}.0/24"]
  }
}