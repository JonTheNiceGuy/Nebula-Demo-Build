resource "azurerm_virtual_machine" "database" {
  name                  = "vm${var.modulename}database"
  location              = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name   = "${azurerm_resource_group.ResourceGroup.name}"
  network_interface_ids = ["${azurerm_network_interface.database.id}"]
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
    name              = "disk${var.modulename}database"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm${var.modulename}database"
    admin_username = "${var.vm_user}"
    custom_data    = <<-EOT
#! /bin/bash -x
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
    OS                    = "ubuntu"
    Nebula_group_database = "true"
    Nebula_ip             = "198.19.1.7/24"
    Bastion_ip            = "${data.azurerm_public_ip.bastion.ip_address}"
  }
}

resource "azurerm_network_interface" "database" {
  name                      = "nic${var.modulename}database"
  location                  = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name       = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_id = "${azurerm_network_security_group.database.id}"

  ip_configuration {
    name                          = "ip${var.modulename}database"
    subnet_id                     = "${azurerm_subnet.Public.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "database" {
  name                = "nsg${var.modulename}database"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}

resource "azurerm_network_security_rule" "bastionSshIn" {
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
  network_security_group_name = "${azurerm_network_security_group.database.name}"
}

resource "azurerm_network_security_rule" "databaseNebulaIn" {
  name                        = "databaseNebulaIn"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.database.name}"
}

resource "azurerm_network_security_rule" "databaseNebulaOut" {
  name                        = "databaseNebulaOut"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.database.name}"
}