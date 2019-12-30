resource "aws_network_interface" "database" {
  depends_on = [aws_nat_gateway.NATGateway]
  subnet_id       = "${aws_subnet.Private.id}"
  security_groups = [
    "${aws_security_group.DatabaseSG.id}",
    "${aws_security_group.CommonManagementSG.id}"
  ]
}

resource "aws_instance" "database" {
  tags = {
    Name                  = "vm${var.modulename}database"
    OS                    = "ubuntu"
    Nebula_ca             = "true"
    Nebula_group_database = "true"
    Nebula_ip             = "198.19.1.4/24"
    Bastion_ip            = "${aws_eip.bastion.public_ip}"
  }

  ami                    = "${var.ami_ubuntu1804}"
  instance_type          = "t2.nano"
  key_name               = "${aws_key_pair.service.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.database.id}"
    device_index         = 0
  }

  user_data = <<USERDATA
#! /bin/bash
hostnamectl set-hostname vm${var.modulename}database
if [ -z "$MYSQL_ROOT_PASSWORD" ]
then
  MYSQL_ROOT_PASSWORD="$(date +%s | sha256sum | base64 | head -c 32)"
fi
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

apt-get update && apt-get install -y mariadb-server

systemctl stop mariadb.service
sed -ri -e "s/^#?\s*bind-address\s+=.*$/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl start mariadb.service
USERDATA
}

resource "aws_security_group" "DatabaseSG" {
  name = "DatabaseSG"
  description = "Database security group"
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "DatabaseSG"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}