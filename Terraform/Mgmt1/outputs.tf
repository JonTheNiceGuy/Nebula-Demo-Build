output "fqdn" {
  value = "awx.${aws_eip.awx.public_ip}.nip.io"
}

output "awxip" {
  value = "${aws_eip.awx.public_ip}"
}

output "admin_password" {
  value = "${var.admin_password}"
}

output "ips" {
  value = <<EOF
awx: ${aws_eip.awx.public_ip}
awx private: ${aws_instance.awx.private_ip}
nebulaca: ${aws_instance.NebulaCA.private_ip}
EOF
}
