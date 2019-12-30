output "ips" {
  value = <<EOF
bastion public: ${aws_eip.bastion.public_ip}
web public: ${aws_instance.web.public_ip}
web private: ${aws_instance.web.private_ip}
database private: ${aws_instance.database.private_ip}
EOF
}
