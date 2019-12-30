resource "azurerm_virtual_machine" "web" {
  name                  = "vm${var.modulename}web"
  location              = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name   = "${azurerm_resource_group.ResourceGroup.name}"
  network_interface_ids = ["${azurerm_network_interface.web.id}"]
  vm_size               = "Standard_B1s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "disk${var.modulename}web"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm${var.modulename}web"
    admin_username = "${var.vm_user}"
    custom_data    = <<-EOT
#! /bin/bash -x
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
sed -ri -e "s!/var/www/!/app/public!g" "/etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf"
systemctl start apache2
EOT
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${var.key}"
      path     = "/home/${var.vm_user}/.ssh/authorized_keys"
    }
  }

  tags = {
    OS               = "ubuntu"
    Nebula_group_web = "true"
    Nebula_ip        = "198.19.1.8/24"
    Bastion_ip       = "${data.azurerm_public_ip.bastion.ip_address}"
  }
}

resource "azurerm_network_interface" "web" {
  name                      = "nic${var.modulename}web"
  location                  = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name       = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_id = "${azurerm_network_security_group.web.id}"

  ip_configuration {
    name                          = "ip${var.modulename}web"
    subnet_id                     = "${azurerm_subnet.Public.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.web.id}"
  }
}

resource "azurerm_public_ip" "web" {
  name                = "pip${var.modulename}web"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  allocation_method   = "Dynamic"
}

data "azurerm_public_ip" "web" {
  depends_on = [azurerm_virtual_machine.web, azurerm_network_interface.web, azurerm_public_ip.web]
  name                = "${azurerm_public_ip.web.name}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg${var.modulename}web"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}

resource "azurerm_network_security_rule" "webSshIn" {
  name                        = "bastionSshIn"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${azurerm_network_interface.bastion.private_ip_address}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.web.name}"
}

resource "azurerm_network_security_rule" "webNebulaIn" {
  name                        = "webNebulaIn"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.web.name}"
}

resource "azurerm_network_security_rule" "webNebulaOut" {
  name                        = "webNebulaOut"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.web.name}"
}

resource "azurerm_network_security_rule" "webHttpAccessIn" {
  name                        = "webHttpAccessIn"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.web.name}"
}

resource "azurerm_network_security_rule" "webHttpsAccessIn" {
  name                        = "webHttpsAccessIn"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.web.name}"
}