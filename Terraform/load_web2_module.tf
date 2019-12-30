module "Web2" {
  source = "./Web2"
  modulename = "web2"
  public_first_three_octets = "198.18.5"
  private_first_three_octets = "198.18.6"
  myip = "${trimspace(data.http.icanhazip.body)}/32"
  key = "${data.local_file.key_file.content}"
  awx_public_ip = "${module.Mgmt1.awxip}"
  Region = "Central US"
  vm_user = "ubuntu"
}

output "Web2_IPs" {
  value = <<EOF
${module.Web2.ips}
EOF
}