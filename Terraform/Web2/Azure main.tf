variable "modulename" {}
variable "public_first_three_octets" {}
variable "private_first_three_octets" {}
variable "myip" {}
variable "key" {}
variable "awx_public_ip" {}
variable "Region" {}
variable "vm_user" {}

resource "azurerm_resource_group" "ResourceGroup" {
  name     = "${var.modulename}ResourceGroup"
  location = "${var.Region}"
}

resource "azurerm_virtual_network" "VNet" {
  name                = "n${var.modulename}"
  address_space       = ["${var.public_first_three_octets}.0/24","${var.private_first_three_octets}.0/24"]
  location            = "${azurerm_resource_group.ResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.ResourceGroup.name}"
}