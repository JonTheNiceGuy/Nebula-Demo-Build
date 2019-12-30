output "ips" {
  value = <<EOF
bastion public: ${data.azurerm_public_ip.bastion.ip_address}
web public: ${data.azurerm_public_ip.web.ip_address}
web private: ${azurerm_network_interface.web.private_ip_address}
database private: ${azurerm_network_interface.database.private_ip_address}
EOF
}
