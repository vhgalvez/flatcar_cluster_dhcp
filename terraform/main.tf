terraform {
  required_version = ">= 0.13.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.13.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "base" {
  name   = "flatcar-base"
  source = var.base_image
  pool   = var.storage_pool
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  for_each       = toset(var.machines)
  name           = "${var.cluster_name}-${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.base.id
  pool           = var.storage_pool
  format         = "qcow2"
}

resource "libvirt_network" "kube_network" {
  name      = "k8s-network"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["10.17.3.0/24"]

  dhcp {
    enabled = true
    range {
      start = "10.17.3.2"
      end   = "10.17.3.254"
    }
  }
}

data "ct_config" "vm_ignitions" {
  for_each = toset(var.machines)
  content = templatefile("${path.module}/configs/${each.key}-config.yaml.tmpl", {
    ssh_keys  = var.ssh_keys,
    name      = each.key,
    hostname  = "${each.key}.${var.cluster_name}.${var.cluster_domain}"
  })
}

resource "libvirt_ignition" "ignition" {
  for_each = data.ct_config.vm_ignitions
  name     = "${var.cluster_name}-${each.key}-ignition"
  pool     = var.storage_pool
  content  = each.value.rendered
}

resource "libvirt_domain" "machine" {
  for_each = toset(var.machines)
  name     = "${var.cluster_name}-${each.key}"
  vcpu     = var.virtual_cpus
  memory   = var.virtual_memory

  coreos_ignition = libvirt_ignition.ignition[each.key].id

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  network_interface {
    network_id = libvirt_network.kube_network.id
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}