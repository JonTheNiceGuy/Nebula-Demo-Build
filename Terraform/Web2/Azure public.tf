resource "azurerm_subnet" "Public" {
  name                 = "s${var.modulename}public"
  resource_group_name  = "${azurerm_resource_group.ResourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.VNet.name}"
  address_prefix       = "${var.public_first_three_octets}.0/24"
}