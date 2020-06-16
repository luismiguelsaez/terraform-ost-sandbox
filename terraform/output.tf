output "ssh_private_key" {
  value = tls_private_key.sandbox.private_key_pem
}

output "floating_ip_management" {
  value = openstack_networking_floatingip_v2.management.*.address
}