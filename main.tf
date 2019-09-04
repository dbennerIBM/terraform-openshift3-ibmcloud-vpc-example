resource "random_id" "tag" {
  byte_length = 4
}

resource "tls_private_key" "installkey" {
  algorithm = "RSA"
  rsa_bits = "2048"
}

provider "vsphere" {
  version        = "~> 1.1"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = "${var.vsphere_allow_unverified_ssl}"
}

##################################
#### Collect resource IDs
##################################
data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.vsphere_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  count = "${var.datastore != "" ? 1 : 0}"

  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  count = "${var.datastore_cluster != "" ? 1 : 0}"

  name          = "${var.datastore_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_cluster}/Resources/${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "private_network" {
  name          = "${var.private_network_label}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "public_network" {
  count         = "${var.public_network_label != "" ? 1 : 0}"
  name          = "${var.public_network_label}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Create a folder
resource "vsphere_folder" "ocpenv" {
  count = "${var.folder != "" ? 1 : 0}"
  path = "${var.folder}"
  type = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

locals  {
  folder_path = "${var.folder != "" ?
        element(concat(vsphere_folder.ocpenv.*.path, list("")), 0)
        : ""}"
}

module "infrastructure" {
  source                       = "github.com/ibm-cloud-architecture/terraform-openshift3-infra-vmware"

  # vsphere information
  vsphere_server               = "${var.vsphere_server}"
  vsphere_cluster_id           = "${data.vsphere_compute_cluster.cluster.id}"
  vsphere_datacenter_id        = "${data.vsphere_datacenter.dc.id}"
  vsphere_resource_pool_id     = "${data.vsphere_resource_pool.pool.id}"
  private_network_id           = "${data.vsphere_network.private_network.id}"
  public_network_id            = "${var.public_network_label != "" ? data.vsphere_network.public_network.0.id : ""}"
  datastore_id                 = "${var.datastore != "" ? data.vsphere_datastore.datastore.0.id : ""}"
  datastore_cluster_id         = "${var.datastore_cluster != "" ? data.vsphere_datastore_cluster.datastore_cluster.0.id : ""}"
  folder_path                  = "${local.folder_path}"

  instance_name                = "${var.hostname_prefix}-${random_id.tag.hex}"

  public_staticipblock         = "${var.public_staticipblock}"
  public_staticipblock_offset  = "${var.public_staticipblock_offset}"
  public_gateway               = "${var.public_gateway}"
  public_netmask               = "${var.public_netmask}"
  public_domain                = "${var.public_domain}"
  public_dns_servers           = "${var.public_dns_servers}"
  
  private_staticipblock        = "${var.private_staticipblock}"
  private_staticipblock_offset = "${var.private_staticipblock_offset}"
  private_netmask              = "${var.private_netmask}"
  private_gateway              = "${var.private_gateway}"
  private_domain               = "${var.private_domain}"
  private_dns_servers          = "${var.private_dns_servers}"

  # how to ssh into the template
  template                     = "${var.template}"
  template_ssh_user            = "${var.ssh_user}"
  template_ssh_password        = "${var.ssh_password}"
  template_ssh_private_key     = "${file(var.ssh_private_key_file)}"

  # the keys to be added between bastion host and the VMs
  ssh_private_key              = "${tls_private_key.installkey.private_key_pem}"
  ssh_public_key               = "${tls_private_key.installkey.public_key_openssh}"

  # information about VM types
  master                       = "${var.master}"
  infra                        = "${var.infra}"
  worker                       = "${var.worker}"
  storage                      = "${var.storage}"
  bastion                      = "${var.bastion}"
}

#module "console_loadbalancer" {
#    source                  = "github.com/ibm-cloud-architecture/terraform-lb-haproxy-vmware"
#
#    vsphere_server                = "${var.vsphere_server}"
#    vsphere_allow_unverified_ssl  = "${var.vsphere_allow_unverified_ssl}"
#    
#    vsphere_datacenter_id     = "${data.vsphere_datacenter.dc.id}"
#    vsphere_cluster_id        = "${data.vsphere_compute_cluster.cluster.id}"
#    vsphere_resource_pool_id  = "${data.vsphere_resource_pool.pool.id}"
#    datastore_id              = "${var.datastore != "" ? data.vsphere_datastore.datastore.0.id : ""}"
#    datastore_cluster_id      = "${var.datastore_cluster != "" ? data.vsphere_datastore_cluster.datastore_cluster.0.id : ""}"
#
#    # Folder to provision the new VMs in, does not need to exist in vSphere
#    folder_path               = "${local.folder_path}"
#    instance_name             = "${var.hostname_prefix}-${random_id.tag.hex}-console"
#
#    private_network_id = "${data.vsphere_network.private_network.id}"
#    private_ip_address = "${cidrhost(var.private_staticipblock, var.private_staticipblock_offset + var.bastion["nodes"] + var.master["nodes"] + var.infra["nodes"] + var.worker["nodes"] + var.storage["nodes"] + 1)}"
#    private_netmask = "${var.private_netmask}"
#    private_gateway = "${var.private_gateway}"
#    private_domain               = "${var.private_domain}"
#
#    public_network_id = "${var.public_network_label != "" ? data.vsphere_network.public_network.0.id : ""}"
#    public_ip_address = "${var.public_network_label != "" ? cidrhost(var.public_staticipblock, var.public_staticipblock_offset + var.bastion["nodes"] + 1) : ""}"
#    public_netmask = "${var.public_network_label != "" ? var.public_netmask: ""}"
#    public_gateway = "${var.public_network_label != "" ? var.public_gateway : ""}"
#    public_domain               = "${var.public_domain}"
#
#    dns_servers = compact(concat(var.public_dns_servers, var.private_dns_servers))
#
#    # how to ssh into the template
#    template                         = "${var.template}"
#    template_ssh_user                = "${var.ssh_user}"
#    template_ssh_password            = "${var.ssh_password}"
#    template_ssh_private_key         = "${file(var.ssh_private_key_file)}"
#
#    rhn_username       = "${var.rhn_username}"
#    rhn_password       = "${var.rhn_password}"
#    rhn_poolid         = "${var.rhn_poolid}"
#
#    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
#
#    frontend = ["443"]
#    backend = {
#        "443" = "${join(",", module.infrastructure.master_private_ip)}"
#    }
#}

#module "app_loadbalancer" {
#    source                  = "github.com/ibm-cloud-architecture/terraform-lb-haproxy-vmware"
#
#    vsphere_server                = "${var.vsphere_server}"
#    vsphere_allow_unverified_ssl  = "${var.vsphere_allow_unverified_ssl}"
#    
#    vsphere_datacenter_id     = "${data.vsphere_datacenter.dc.id}"
#    vsphere_cluster_id        = "${data.vsphere_compute_cluster.cluster.id}"
#    vsphere_resource_pool_id  = "${data.vsphere_resource_pool.pool.id}"
#    datastore_id              = "${var.datastore != "" ? data.vsphere_datastore.datastore.0.id : ""}"
#    datastore_cluster_id      = "${var.datastore_cluster != "" ? data.vsphere_datastore_cluster.datastore_cluster.0.id : ""}"
#
#    # Folder to provision the new VMs in, does not need to exist in vSphere
#    folder_path               = "${local.folder_path}"
#    instance_name             = "${var.hostname_prefix}-${random_id.tag.hex}-app"
#
#    private_network_id  = "${data.vsphere_network.private_network.id}"
#    private_ip_address  = "${cidrhost(var.private_staticipblock, var.private_staticipblock_offset + var.bastion["nodes"] + var.master["nodes"] + var.infra["nodes"] + var.worker["nodes"] + var.storage["nodes"] + 2)}"
#    private_netmask     = "${var.private_netmask}"
#    private_gateway     = "${var.private_gateway}"
#    private_domain      = "${var.private_domain}"
#
#    public_network_id   = "${var.public_network_label != "" ? data.vsphere_network.public_network.0.id : ""}"
#    public_ip_address   = "${var.public_network_label != "" ? cidrhost(var.public_staticipblock, var.public_staticipblock_offset + var.bastion["nodes"] + 2) : ""}"
#    public_netmask      = "${var.public_network_label != "" ? var.public_netmask : ""}"
#    public_gateway      = "${var.public_network_label != "" ? var.public_gateway : ""}"
#    public_domain       = "${var.public_domain}"
#
#    dns_servers = compact(concat(var.public_dns_servers, var.private_dns_servers))
#
#    # how to ssh into the template
#    template                         = "${var.template}"
#    template_ssh_user                = "${var.ssh_user}"
#    template_ssh_password            = "${var.ssh_password}"
#    template_ssh_private_key         = "${file(var.ssh_private_key_file)}"
#
#    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
#
#    rhn_username       = "${var.rhn_username}"
#    rhn_password       = "${var.rhn_password}"
#    rhn_poolid         = "${var.rhn_poolid}"
#
#    frontend = ["80", "443"]
#    backend = {
#        "443" = "${join(",", module.infrastructure.infra_private_ip)}"
#        "80" = "${join(",", module.infrastructure.infra_private_ip)}"
#    }
#}

locals {
  rhn_all_nodes = "${concat(
        "${list(module.infrastructure.bastion_public_ip)}",
        "${module.infrastructure.master_private_ip}",
        "${module.infrastructure.infra_private_ip}",
        "${module.infrastructure.worker_private_ip}",
        "${module.infrastructure.storage_private_ip}"
    )}"

  rhn_all_count = "${var.bastion["nodes"] + var.master["nodes"] + var.infra["nodes"] + var.worker["nodes"] + var.storage["nodes"]}"
  openshift_node_count = "${var.master["nodes"] + var.worker["nodes"] + var.infra["nodes"] +  var.storage["nodes"]}"
}

module "rhnregister" {
  source             = "github.com/ibm-cloud-architecture/terraform-openshift-rhnregister"

  bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
  bastion_ssh_user        = "${var.ssh_user}"
  bastion_ssh_password    = "${var.ssh_password}"
  bastion_ssh_private_key = "${file(var.ssh_private_key_file)}"

  ssh_user           = "${var.ssh_user}"
  ssh_private_key    = "${tls_private_key.installkey.private_key_pem}"

  rhn_username       = "${var.rhn_username}"
  rhn_password       = "${var.rhn_password}"
  rhn_poolid         = "${var.rhn_poolid}"
  all_nodes          = "${local.rhn_all_nodes}"
  all_count          = "${local.rhn_all_count}"
}

#module "dns_private" {
#    source                  = "github.com/ibm-cloud-architecture/terraform-dns-rfc2136"
#
#    node_count = "${var.bastion["nodes"] + 
#      var.master["nodes"] + 
#      var.worker["nodes"] + 
#      var.infra["nodes"] + 
#      var.storage["nodes"] +
#      1 +
#      1}"
#
#    node_hostnames = concat(
#            list(module.infrastructure.bastion_hostname),
#            module.infrastructure.master_hostname,
#            module.infrastructure.worker_hostname,
#            module.infrastructure.infra_hostname,
#            module.infrastructure.storage_hostname,
#            list(module.console_loadbalancer.node_hostname),
#            list(module.app_loadbalancer.node_hostname))
#
#    node_ips = concat(
#            list(module.infrastructure.bastion_private_ip),
#            module.infrastructure.master_private_ip,
#            module.infrastructure.worker_private_ip,
#            module.infrastructure.infra_private_ip,
#            module.infrastructure.storage_private_ip,
#            list(module.console_loadbalancer.node_private_ip),
#            list(module.app_loadbalancer.node_private_ip))
#
#    zone_name               = "${var.private_domain}."
#    dns_server              = "${element(var.private_dns_servers, 0)}"
#
#    create_node_ptr_records = true
#
#    key_name = "${var.dns_key_name}"
#    key_algorithm = "${var.dns_key_algorithm}"
#    key_secret = "${var.dns_key_secret}"
#    record_ttl = "${var.dns_record_ttl}" 
#}


#module "dns_public" {
#    source                  = "github.com/ibm-cloud-architecture/terraform-dns-cloudflare"
#
#    cloudflare_email         = "${var.cloudflare_email}"
#    cloudflare_token         = "${var.cloudflare_token}"
#    cloudflare_zone          = "${var.cloudflare_zone}"
#
#    num_cnames = 2
#    cnames = "${zipmap(
#        concat(
#            list("${var.master_cname}"),
#            list("*.${var.app_cname}")
#        ),
#        concat(
#            list("${module.console_loadbalancer.node_hostname}.${var.private_domain}"),
#            list("${module.app_loadbalancer.node_hostname}.${var.private_domain}")
#        )
#    )}"
#}

#module "certs" {
#    source                   = "github.com/ibm-cloud-architecture/terraform-certs-letsencrypt-cloudflare?ref=v1.0"
#
#    cloudflare_email         = "${var.cloudflare_email}"
#    cloudflare_token         = "${var.cloudflare_token}"
#    letsencrypt_email        = "${var.letsencrypt_email}"
#
#    cluster_cname            = "${var.master_cname}"
#    app_subdomain            = "${var.app_cname}"
#}

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
}

module "etchosts" {
    source = "github.com/ibm-cloud-architecture/terraform-dns-etc-hosts"

    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_ssh_user        = "${var.ssh_user}"
    bastion_ssh_password    = "${var.ssh_password}"
    bastion_ssh_private_key = "${file(var.ssh_private_key_file)}"

    ssh_user           = "${var.ssh_user}"
    ssh_private_key    = "${tls_private_key.installkey.private_key_pem}"
    
    node_ips                = "${local.all_ips}"
    node_hostnames          = "${local.all_hostnames}"
    domain                  = "${var.private_domain}"

    num_nodes = "${local.openshift_node_count}"
}

module "openshift" {
  source = "github.com/ibm-cloud-architecture/terraform-openshift3-deploy"

  dependson = [
    "${module.rhnregister.registered_resource}"
  ]

  # cluster nodes
  node_count              = "${local.openshift_node_count}"
  master_private_ip       = "${module.infrastructure.master_private_ip}"
  infra_private_ip        = "${module.infrastructure.infra_private_ip}"
  worker_private_ip       = "${module.infrastructure.worker_private_ip}"
  storage_private_ip      = "${module.infrastructure.storage_private_ip}"
  master_hostname         = "${formatlist("%v.%v", module.infrastructure.master_hostname, var.private_domain)}"
  infra_hostname          = "${formatlist("%v.%v", module.infrastructure.infra_hostname, var.private_domain)}"
  worker_hostname         = "${formatlist("%v.%v", module.infrastructure.worker_hostname, var.private_domain)}"
  storage_hostname        = "${formatlist("%v.%v", module.infrastructure.storage_hostname, var.private_domain)}"

  # second disk is docker block device, in VMware it's /dev/sdb
  docker_block_device     = "/dev/sdb"
  
  # third disk on storage nodes, in VMware it's /dev/sdc
  gluster_block_devices   = ["/dev/sdc"]

  # connection parameters
  bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
  bastion_ssh_user        = "${var.ssh_user}"
  bastion_ssh_password    = "${var.ssh_password}"
  bastion_ssh_private_key = "${file(var.ssh_private_key_file)}"

  ssh_user                = "${var.ssh_user}"
  ssh_private_key         = "${tls_private_key.installkey.private_key_pem}"

  cloudprovider           = {
      kind = "vsphere"
  }

  ose_version             = "${var.ose_version}"
  ose_deployment_type     = "${var.ose_deployment_type}"
  image_registry          = "${var.image_registry}"
  image_registry_username = "${var.image_registry_username == "" ? var.rhn_username : var.image_registry_username}"
  image_registry_password = "${var.image_registry_password == "" ? var.rhn_password : var.image_registry_password}"

  # internal API endpoint
  master_cluster_hostname = "${var.master_cname}"

  # public endpoints - must be in DNS
  cluster_public_hostname = "${var.master_cname}"
  app_cluster_subdomain   = "${var.app_cname}"

  registry_volume_size    = "${var.registry_volume_size}"

  pod_network_cidr        = "${var.network_cidr}"
  service_network_cidr    = "${var.service_network_cidr}"
  host_subnet_length      = "${var.host_subnet_length}"

#  master_cert             = "${module.certs.master_cert}"
#  master_key              = "${module.certs.master_key}"
#  router_cert             = "${module.certs.router_cert}"
#  router_key              = "${module.certs.router_key}"
#  router_ca_cert          = "${module.certs.ca_cert}"
}