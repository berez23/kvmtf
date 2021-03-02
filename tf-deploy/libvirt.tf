terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}

provider "libvirt" {
 uri =  "qemu+ssh://root@176.9.156.87/system?socket=/var/run/libvirt/libvirt-sock"
}

# Create pools 
resource "libvirt_pool" "ubuntu" {
  name = "ubuntupool"
  type = "dir"
  path = "/home/ubuntu-pool"
}

# Create image
resource "libvirt_volume" "image-qcow2" {
  name = "ubuntu-amd64.qcow2"
  pool = libvirt_pool.ubuntu.name
  source = "${path.module}/downloads/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}

# add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = libvirt_pool.ubuntu.name
  user_data = "data.template_file.user_data_rendered"
  }

data "template_file" "user_data" {
  template = file("${path.module}/scripts/cloud_init.cfg")
}

resource "libvirt_domain" "cere_vm" {
  name = "ubuntu-20.04"
  memory = "1024"
  vcpu = 1
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  network_interface {
  network_name = "default"
  }

console {
  type = "pty"
  target_type ="serial"
  target_port = "0"
}

disk {
	volume_id = libvirt_volume.image-qcow2.id
}

graphics {
	type = "spice"
	listen_type = "address"
	autoport = true
}


}

