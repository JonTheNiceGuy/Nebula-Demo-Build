data "local_file" "vault_file" {
  filename = "${path.module}/vaultfile"
}

data "local_file" "key_file" {
  filename = "${path.module}/id_rsa.pub"
}

data "local_file" "admin_password" {
  filename = "${path.module}/admin_password"
}