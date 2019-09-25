resource "tls_private_key" "installkey" {
  algorithm   = "RSA"
}

provider "ibm" {
  generation = "1"
  ibmcloud_timeout = "60"
}

module "infrastructure" {
  source                       = "github.com/jkwong888/terraform-openshift3-infra-ibmcloud-vpc"

  key_name = ["${var.key_name}"]
  deployment = "${var.deployment}"

  domain = "${var.domain}"
  os_image = "red-7.x-amd64"

  vpc_region = "${var.vpc_region}"
  vpc_address_prefix = "${var.vpc_address_prefix}"
  vpc_subnet_cidr = "${var.vpc_subnet_cidr}"

  control = "${var.control}"
  master = "${var.master}"
  infra = "${var.infra}"
  worker = "${var.worker}"
  glusterfs = "${var.glusterfs}"

  ssh_user = "ocpdeploy"
  ssh_private_key = "${tls_private_key.installkey.private_key_pem}"
  ssh_public_key = "${tls_private_key.installkey.public_key_openssh}"
}

locals {
  rhn_all_nodes = "${concat(
        "${list(module.infrastructure.bastion_public_ip)}",
        "${module.infrastructure.master_private_ip}",
        "${module.infrastructure.infra_private_ip}",
        "${module.infrastructure.worker_private_ip}",
        "${module.infrastructure.storage_private_ip}"
    )}"

  rhn_all_count = "${lookup(var.control, "nodes", 1) + 
                     lookup(var.master, "nodes", 3) + 
                     lookup(var.infra, "nodes", 3) + 
                     lookup(var.worker, "nodes", 3) + 
                     lookup(var.glusterfs, "nodes", 3)}"
  openshift_node_count = "${lookup(var.master, "nodes", 3) + 
                            lookup(var.worker, "nodes", 3) + 
                            lookup(var.infra, "nodes", 3) +  
                            lookup(var.glusterfs, "nodes", 3)}"
}

module "rhnregister" {
  source             = "github.com/ibm-cloud-architecture/terraform-openshift-rhnregister"

  bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
  bastion_ssh_user        = "ocpdeploy"
  bastion_ssh_private_key = "${tls_private_key.installkey.private_key_pem}"

  ssh_user           = "ocpdeploy"
  ssh_private_key    = "${tls_private_key.installkey.private_key_pem}"

  rhn_username       = "${var.rhn_username}"
  rhn_password       = "${var.rhn_password}"
  rhn_poolid         = "${var.rhn_poolid}"
  all_nodes          = "${local.rhn_all_nodes}"
  all_count          = "${local.rhn_all_count}"
}

# ####################################################
# Generate /etc/hosts files
# ####################################################
locals {
  all_ips = "${concat(
    "${list(module.infrastructure.bastion_private_ip)}",
    "${module.infrastructure.master_private_ip}",
    "${module.infrastructure.infra_private_ip}",
    "${module.infrastructure.worker_private_ip}",
    "${module.infrastructure.storage_private_ip}",
  )}"
  all_hostnames = "${concat(
    "${list(module.infrastructure.bastion_hostname)}",
    "${module.infrastructure.master_hostname}",
    "${module.infrastructure.infra_hostname}",
    "${module.infrastructure.worker_hostname}",
    "${module.infrastructure.storage_hostname}",
  )}"

  all_count = "${lookup(var.control, "nodes", 1) + 
                     lookup(var.master, "nodes", 3) + 
                     lookup(var.infra, "nodes", 3) + 
                     lookup(var.worker, "nodes", 3) + 
                     lookup(var.glusterfs, "nodes", 3)}"
}

module "etchosts" {
    source = "github.com/ibm-cloud-architecture/terraform-dns-etc-hosts"

    dependson = [
      "${module.rhnregister.registered_resource}",
    ]

    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_ssh_user        = "ocpdeploy"
    bastion_ssh_private_key = "${tls_private_key.installkey.private_key_pem}"

    ssh_user           = "ocpdeploy"
    ssh_private_key    = "${tls_private_key.installkey.private_key_pem}"
    
    node_ips                = "${local.all_ips}"
    node_hostnames          = "${local.all_hostnames}"
    domain                  = "${var.domain}"

    num_nodes = "${local.all_count}"
}


module "dns_public" {
    source                  = "github.com/ibm-cloud-architecture/terraform-dns-cloudflare"

    cloudflare_email         = "${var.cloudflare_email}"
    cloudflare_token         = "${var.cloudflare_token}"
    cloudflare_zone          = "${var.cloudflare_zone}"

    num_cnames = 2
    cnames = "${zipmap(
        concat(
            list("${var.master_cname}"),
            list("*.${var.app_cname}")
        ),
        concat(
            list("${module.infrastructure.master_loadbalancer_hostname}"),
            list("${module.infrastructure.app_loadbalancer_hostname}")
        )
    )}"
}


module "certs" {
  source = "github.com/ibm-cloud-architecture/terraform-certs-letsencrypt-cloudflare"

  letsencrypt_email ="${var.letsencrypt_email}"
  app_subdomain = "${var.app_cname}"
  cluster_cname = "${var.master_cname}"
}

module "openshift" {
  source = "github.com/ibm-cloud-architecture/terraform-openshift3-deploy"

  dependson = [
    "${module.rhnregister.registered_resource}"
  ]

  # cluster nodes
  node_count              = "${local.openshift_node_count}"
  master_count            = "${lookup(var.master, "nodes", 3)}"
  infra_count             = "${lookup(var.infra, "nodes", 3)}"
  worker_count            = "${lookup(var.worker, "nodes", 3)}"
  storage_count           = "${lookup(var.glusterfs, "nodes", 3)}"
  master_private_ip       = "${module.infrastructure.master_private_ip}"
  infra_private_ip        = "${module.infrastructure.infra_private_ip}"
  worker_private_ip       = "${module.infrastructure.worker_private_ip}"
  storage_private_ip      = "${module.infrastructure.storage_private_ip}"
  master_hostname         = "${formatlist("%v.%v", module.infrastructure.master_hostname, var.domain)}"
  infra_hostname          = "${formatlist("%v.%v", module.infrastructure.infra_hostname, var.domain)}"
  worker_hostname         = "${formatlist("%v.%v", module.infrastructure.worker_hostname, var.domain)}"
  storage_hostname        = "${formatlist("%v.%v", module.infrastructure.storage_hostname, var.domain)}"

  # second disk is docker block device, in ibm cloud it's /dev/xvdc
  docker_block_device     = "/dev/xvdc"
  
  # third disk on storage nodes, in ibm cloud it's /dev/xvde
  gluster_block_devices   = ["/dev/xvde"]

  # connection parameters
  bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
  bastion_ssh_user        = "ocpdeploy"
  bastion_ssh_private_key = "${tls_private_key.installkey.private_key_pem}"

  ssh_user                = "ocpdeploy"
  ssh_private_key         = "${tls_private_key.installkey.private_key_pem}"

  ose_version             = "${var.ose_version}"
  ose_deployment_type     = "${var.ose_deployment_type}"
  image_registry          = "${var.image_registry}"
  image_registry_username = "${var.image_registry_username == "" ? var.rhn_username : var.image_registry_username}"
  image_registry_password = "${var.image_registry_password == "" ? var.rhn_password : var.image_registry_password}"

  # internal API endpoint -- lb url
  master_cluster_hostname = "${module.infrastructure.master_loadbalancer_hostname}"

  # public endpoints - must be in DNS
  cluster_public_hostname = "${var.master_cname}"
  app_cluster_subdomain   = "${var.app_cname}"

  registry_volume_size    = "${var.registry_volume_size}"

  pod_network_cidr        = "${var.network_cidr}"
  service_network_cidr    = "${var.service_network_cidr}"
  host_subnet_length      = "${var.host_subnet_length}"

  storageclass_file       = "${var.storage_class}"
  storageclass_block      = "${var.storage_class}"

  master_cert             = "${module.certs.master_cert}"
  master_key              = "${module.certs.master_key}"
  router_cert             = "${module.certs.router_cert}"
  router_key              = "${module.certs.router_key}"
  router_ca_cert          = "${module.certs.ca_cert}"
}