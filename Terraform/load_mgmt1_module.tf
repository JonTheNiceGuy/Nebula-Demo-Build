module "Mgmt1" {
  source = "./Mgmt1"
  modulename = "Mgmt1"
  public_first_three_octets = "198.18.1"
  private_first_three_octets = "198.18.2"
  ami_centos8 = "${var.ami_centos8}"
  ami_ubuntu1804 = "${data.aws_ami.ubuntu.id}"
  ami_win2019 = "${var.ami_win2019}"
  myip = "${trimspace(data.http.icanhazip.body)}/32"
  admin_password = "${trimspace(data.local_file.admin_password.content)}"
  key = "${data.local_file.key_file.content}"
  VaultFile = "${data.local_file.vault_file.content}"
}

output "Mgmt1_IPs" {
  value = <<EOF
${module.Mgmt1.ips}
EOF
}