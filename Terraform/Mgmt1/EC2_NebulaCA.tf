resource "aws_network_interface" "NebulaCA" {
  depends_on = [aws_nat_gateway.NATGateway]
  subnet_id       = "${aws_subnet.Private.id}"
  security_groups = [
    "${aws_security_group.ServiceSG.id}",
    "${aws_security_group.CommonManagementSG.id}"
  ]
}

resource "aws_instance" "NebulaCA" {
  tags = {
    Name            = "vm${var.modulename}nebulaca"
    OS              = "ubuntu"
    Nebula_ca       = "true"
    Nebula_group_ca = "true"
    Nebula_ip       = "198.19.1.2/24"
  }

  ami                    = "${var.ami_ubuntu1804}"
  instance_type          = "t2.nano"
  key_name               = "${aws_key_pair.service.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.NebulaCA.id}"
    device_index         = 0
  }

  user_data = <<USERDATA
#! /bin/bash
hostnamectl set-hostname vm${var.modulename}nebulaca
apt update && apt install python2.7
USERDATA
}
