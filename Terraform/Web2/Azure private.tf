resource "azurerm_subnet" "Private" {
  name                 = "s${var.modulename}private"
  resource_group_name  = "${azurerm_resource_group.ResourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.VNet.name}"
  address_prefix       = "${var.private_first_three_octets}.0/24"
}