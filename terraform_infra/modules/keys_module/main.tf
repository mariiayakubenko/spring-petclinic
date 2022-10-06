resource "tls_private_key" "rsa_key" {
  for_each  = toset(var.hosts)
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "rsa_key" {
  for_each = toset(var.hosts)
  name     = "${each.key}_key"
  type     = "String"
  value    = tls_private_key.rsa_key[each.key].private_key_openssh
}
