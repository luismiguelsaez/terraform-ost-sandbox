locals {
  management_external_network_id = "0a5ca4de-6d61-484d-b985-cb8ee4cc2348"
  management_floating_ip_pool    = "ext_mgmt"
}

resource "openstack_networking_router_v2" "management" {
  name                = "management"
  admin_state_up      = true
  external_network_id = local.management_external_network_id
}

data "openstack_compute_availability_zones_v2" "zones" {}

resource "openstack_networking_network_v2" "management" {
  name           = "management"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "management" {
  count = length(data.openstack_compute_availability_zones_v2.zones.names)

  name       = format("management-%02d",count.index + 1)
  network_id = openstack_networking_network_v2.management.id
  cidr       = cidrsubnet("172.16.10.0/16",8,count.index)
  dns_nameservers = ["10.26.205.34","10.26.205.35"]
  ip_version = 4
}

resource "openstack_networking_router_interface_v2" "router-interfaces" {
  count = length(data.openstack_compute_availability_zones_v2.zones.names)

  router_id = openstack_networking_router_v2.management.id
  subnet_id = openstack_networking_subnet_v2.management[count.index].id
}

resource "openstack_compute_secgroup_v2" "management" {
  name         = "management"
  description  = "Managemente security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "tls_private_key" "sandbox" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "openstack_compute_keypair_v2" "sandbox" {
  name       = "sandbox"
  public_key = tls_private_key.sandbox.public_key_openssh
}

resource "openstack_networking_port_v2" "sandbox" {
  count = length(data.openstack_compute_availability_zones_v2.zones.names)

  name               = format("management-%02d",count.index + 1)
  network_id         = openstack_networking_network_v2.management.id
  security_group_ids = [ openstack_compute_secgroup_v2.management.id ]
  admin_state_up     = true

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.management[count.index].id
  }
}

resource "openstack_compute_instance_v2" "sandbox" {
  count = length(data.openstack_compute_availability_zones_v2.zones.names)

  name              = format("sandbox-%02d",count.index + 1)
  availability_zone = element(data.openstack_compute_availability_zones_v2.zones.names,count.index)
  image_name        = "TID-RH77.20200601"
  flavor_name       = "TID-04CPU-08GB-20GB"
  key_pair          = openstack_compute_keypair_v2.sandbox.name

  metadata = {
    environment = "sandbox"
  }

  network {
    port = openstack_networking_port_v2.sandbox[count.index].id
  }
}

resource "openstack_networking_floatingip_v2" "management" {
  count = length(data.openstack_compute_availability_zones_v2.zones.names)

  pool    = local.management_floating_ip_pool
  port_id = openstack_networking_port_v2.sandbox[count.index].id
}