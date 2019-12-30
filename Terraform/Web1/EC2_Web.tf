resource "aws_eip" "web" {
  vpc = true
}

resource "aws_eip_association" "web" {
  network_interface_id = "${aws_network_interface.web.id}"
  allocation_id        = "${aws_eip.web.id}"
}

resource "aws_network_interface" "web" {
  depends_on = [aws_eip.web]
  subnet_id       = "${aws_subnet.Public.id}"
  security_groups = [
    "${aws_security_group.WebSG.id}",
    "${aws_security_group.CommonManagementSG.id}"
  ]
}

resource "aws_instance" "web" {
  depends_on = [aws_network_interface.web]
  tags = {
    Name             = "vm${var.modulename}web"
    OS               = "ubuntu"
    Nebula_group_web = "true"
    Nebula_ip        = "198.19.1.5/24"
    Bastion_ip       = "${aws_eip.bastion.public_ip}"
  }

  ami           = "${var.ami_ubuntu1804}"
  instance_type = "t2.nano"
  key_name      = "${aws_key_pair.service.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.web.id}"
    device_index         = 0
  }

  user_data = <<USERDATA
#! /bin/bash
hostnamectl set-hostname vm${var.modulename}web
apt update && apt install -y  apache2 \
                              libapache2-mod-fcgid \
                              php-fpm \
                              curl \
                              ca-certificates \
                              nodejs \
                              npm \
                              php-gd \
                              php-mysql \
                              php-sqlite3 \
                              php-mbstring \
                              php-zip \
                              php-exif \
                              php-xml \
                              composer

echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
a2enconf servername

a2enmod rewrite
a2enmod proxy_fcgi setenvif
a2enconf php7.2-fpm
systemctl start php7.2-fpm

mkdir -p /app/public
echo "<?php phpinfo();" > /app/public/index.php
chown -R www-data:www-data /var/www /app
chmod 700 /app /app/public
chmod 600 /app/public/index.php

systemctl stop apache2
sed -ri -e "s!/var/www/html!/app/public!g" "/etc/apache2/sites-available/*.conf"
sed -ri -e "s!/var/www/!/app/public!g" "/etc/apache2/apache2.conf" "/etc/apache2/conf-available/*.conf"
systemctl start apache2
USERDATA
}

resource "aws_security_group" "WebSG" {
  name = "WebSG"
  description = "Web security group"
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "WebSG"
  }

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}