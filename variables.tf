####################################
# vCenter Configuration
####################################
variable "vsphere_server" {}
variable "vsphere_allow_unverified_ssl" {
  default = true
}

variable "vsphere_datacenter" {}
variable "vsphere_cluster" {}
variable "vsphere_resource_pool" {}
variable "datastore" {
  default = ""
}
variable "datastore_cluster" {
  default = ""
}
variable "template" {}
variable "folder" {}

####################################
# Infrastructure Configuration
####################################


variable "hostname_prefix" {
  default = ""
}

variable "ssh_user" {}
variable "ssh_password" {}

variable "ssh_private_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "ssh_public_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "bastion_ssh_private_key_file" {
  default = "~/.ssh/id_rsa"
}
variable "private_network_label" {}
variable "private_domain" {}
variable "private_staticipblock" {
  default = ""
}
variable "private_staticipblock_offset" {
  default = 0
}

variable "bastion_private_ip" {
  type = "list"
  default = []
}

variable "master_private_ip" {
  type = "list"
  default = []
}

variable "infra_private_ip" {
  type = "list"
  default = []
}

variable "worker_private_ip" {
  type = "list"
  default = []
}

variable "storage_private_ip" {
  type = "list"
  default = []
}

variable "private_netmask" {}
variable "private_gateway" {}
variable "private_dns_servers" {
  type = "list"
}

variable "public_network_label" {
  default = ""
}

variable "public_staticipblock" {
  default = "0.0.0.0/0"
}

variable "public_staticipblock_offset" {
  default = "0"
}

variable "public_netmask" {
  default = "0"
}

variable "public_gateway" {
  default = ""
}

variable "public_domain" {
  default = ""
}

variable "public_dns_servers" {
  type = "list"
  default = []
}

variable "bastion" {
  type = "map"

  default = {
    nodes               = "1"
    vcpu                = "2"
    memory              = "8192"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "master" {
  type = "map"

  default = {
    nodes                 = "1"
    vcpu                  = "4"
    memory                = "16384"
    disk_size             = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size      = "100"   # Specify size for docker disk, default 100.
    thin_provisioned      = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub         = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove   = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "infra" {
  type = "map"

  default = {
    nodes               = "1"
    vcpu                = "4"
    memory              = "16384"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "worker" {
  type = "map"

  default = {
    nodes               = "1"
    vcpu                = "8"
    memory              = "16384"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "storage" {
  type = "map"

  default = {
    nodes               = "3"
    vcpu                = "4"
    memory              = "8192"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    gluster_disk_size   = "250"
    gluster_num_disks   = "1"
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

####################################
# RHN Registration
####################################
variable "rhn_username" {}
variable "rhn_password" {}
variable "rhn_poolid" {}


variable "master_cname" {
  default = "master"
}
variable "app_cname" {
  description = "wildcard app domain (don't add the *. prefix)"
  default = "app"
}

####################################
# OpenShift Installation
####################################
variable "network_cidr" {
  default = "10.128.0.0/14"
}

variable "service_network_cidr" {
  default = "172.30.0.0/16"
}

variable "host_subnet_length" {
  default = 9
}

variable "ose_version" {
  default = "3.11"
}

variable "ose_deployment_type" {
  default = "openshift-enterprise"
}

variable "image_registry" {
  default = "registry.redhat.io"
}

variable "image_registry_path" {
  default = "/openshift3/ose-$${component}:$${version}"
}

variable "image_registry_username" {
  default = ""
}

variable "image_registry_password" {
  default = ""
}

variable "registry_volume_size" {
  default = "100"
}

variable "cloudprovider" {
  default = "ibm"
}

variable "icp_binary" {
  default = "nfs://jumper.rtp.raleigh.ibm.com/catalog/rhos/ibm-cloud-private-rhos-3.2.0.1907.tar.gz"
}

variable "icp_install_path" {
  default = "/opt/ibm-cloud-private-rhos-3.2.0"
}

variable "storage_class" {
  default = "glusterfs-storage"
}

variable "vsphere_storage_username" {
  default = ""
}

variable "vsphere_storage_password" {
  default = ""
}

variable "vsphere_storage_datastore" {
  default = ""
}

