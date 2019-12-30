module "Web1" {
  source = "./Web1"
  modulename = "Web1"
  public_first_three_octets = "198.18.3"
  private_first_three_octets = "198.18.4"
  ami_centos8 = "${var.ami_centos8}"
  ami_ubuntu1804 = "${data.aws_ami.ubuntu.id}"
  ami_win2019 = "${var.ami_win2019}"
  myip = "${trimspace(data.http.icanhazip.body)}/32"
  admin_password = "${trimspace(data.local_file.admin_password.content)}"
  key = "${data.local_file.key_file.content}"
  awx_public_ip = "${module.Mgmt1.awxip}"
}

output "Web1_IPs" {
  value = <<EOF
${module.Web1.ips}
EOF
}