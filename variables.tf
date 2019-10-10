variable "key_name" {
  description = "Name or reference of SSH key to provision IBM Cloud instances with"
  default = []
}

variable "deployment" {
  description = "Name of deployment, most objects and hostnames prefixed with this"
  default = "ocp-dev"
}

variable "domain" {
  default = "my-ocp-cluster.com"
}

variable "vpc_region" {
  default   = "us-south"
}

variable "vpc_address_prefix" {
  description = "address prefixes for each zone in the VPC.  the VPC subnet CIDRs for each zone must be within the address prefix."
  default = [ "10.10.0.0/24", "10.11.0.0/24", "10.12.0.0/24" ]
}

variable "vpc_subnet_cidr" {
  default = [ "10.10.0.0/24", "10.11.0.0/24", "10.12.0.0/24" ]
}

##### OCP Instance details ######

variable "control" {
  type = "map"

  default = {
    profile           = "cc1-2x4"

    disk_size         = "100" // GB
    docker_vol_size   = "200" // GB
    disk_profile      = "general-purpose"
    disk_iops         = "0"  // set if disk_profile is "custom"
  }
}

variable "master" {
  type = "map"

  default = {
    nodes             = "3"
    profile           = "bc1-8x32"

    disk_size         = "100" // GB
    docker_vol_size   = "100" // GB

    disk_profile      = "general-purpose"
    disk_iops         = "0"  // set if disk_profile is "custom"

  }
}

variable "infra" {
  type = "map"

  default = {
    nodes       = "3"
    profile           = "bc1-8x32"

    disk_size         = "100" // GB
    docker_vol_size   = "100" // GB
    disk_profile      = "general-purpose"
    disk_iops         = "0"  // set if disk_profile is "custom"

  }
}

variable "worker" {
  type = "map"

  default = {
    nodes       = "3"

    profile           = "bc1-4x16"

    disk_size         = "100" // GB, 25 or 100
    docker_vol_size   = "100" // GB
    disk_profile      = "general-purpose"
    disk_iops         = "0"  // set if disk_profile is "custom"

  }
}

variable "glusterfs" {
  type = "map"

  default = {
    nodes       = "3"

    profile           = "bc1-4x16"

    disk_size         = "100" // GB, 25 or 100
    docker_vol_size   = "100" // GB
    disk_profile      = "general-purpose"
    disk_iops         = "0"  // set if disk_profile is "custom"
    num_gluster_disks = "1"
    gluster_disk_size = "500"   // GB
  }
}



####################################
# RHN Registration
####################################
variable "rhn_username" {}
variable "rhn_password" {}
variable "rhn_poolid" {}


variable "letsencrypt_email" {}

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

variable "storage_class" {
  default = "glusterfs-storage"
}

variable "cloudflare_email" {
  default = ""
}
variable "cloudflare_token" {
  default = ""
}
variable "cloudflare_zone" {
  default = ""
}
