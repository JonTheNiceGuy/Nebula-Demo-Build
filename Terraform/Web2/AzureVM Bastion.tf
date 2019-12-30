resource "azurerm_virtual_machine" "bastion" {
  name                  = "vm${var.modulename}bastion"
  location              = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name   = "${azurerm_resource_group.ResourceGroup.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion.id}"]
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
    name              = "disk${var.modulename}bastion"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm${var.modulename}bastion"
    admin_username = "${var.vm_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${var.key}"
      path     = "/home/${var.vm_user}/.ssh/authorized_keys"
    }
  }

  tags = {
    OS                   = "ubuntu"
    Nebula_group_bastion = "true"
    Nebula_lighthouse    = "true"
    Nebula_ip            = "198.19.1.6/24"
    HasRoleBastion       = "true"
  }
}

resource "azurerm_network_interface" "bastion" {
  name                      = "nic${var.modulename}bastion"
  location                  = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name       = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"

  ip_configuration {
    name                          = "ip${var.modulename}bastion"
    subnet_id                     = "${azurerm_subnet.Public.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip${var.modulename}bastion"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
  allocation_method   = "Dynamic"
}

data "azurerm_public_ip" "bastion" {
  depends_on = [azurerm_virtual_machine.bastion, azurerm_network_interface.bastion, azurerm_public_ip.bastion]
  name                = "${azurerm_public_ip.bastion.name}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg${var.modulename}bastion"
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}

resource "azurerm_network_security_rule" "bastionAwxAccessIn" {
  name                        = "bastionAwxAccessIn"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${var.awx_public_ip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_network_security_rule" "bastionSshOutPrivate" {
  name                        = "bastionSshOutPrivate"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "${var.private_first_three_octets}.0/24"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_network_security_rule" "bastionSshOutPublic" {
  name                        = "bastionSshOutPublic"
  priority                    = 102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "${var.public_first_three_octets}.0/24"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_network_security_rule" "bastionNebulaIn" {
  name                        = "bastionNebulaIn"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_network_security_rule" "bastionNebulaOut" {
  name                        = "bastionNebulaOut"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4242"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.ResourceGroup.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}