# terraform-openshift3-vmware-example

End to end example of deploying Openshift on VMware. In this example we use the following sub-modules:

* [terraform-openshift3-infra-vmware](https://github.com/ibm-cloud-architecture/terraform-openshift3-infra-vmware) - To create VMs on VMware.
* [terraform-openshift-rhnregister](https://github.com/ibm-cloud-architecture/terraform-openshift-rhnregister) - To register all VMs with Red Hat Network subscriptions.
* [terraform-lb-haproxy-vmware](https://github.com/ibm-cloud-architecture/terraform-lb-haproxy-vmware) - To create two HAProxy load balancers (one for the console, one for the application router).
* [terraform-dns-rfc2136](https://github.com/ibm-cloud-architecture/terraform-dns-rfc2136) - To update our private network DNS server with all required records on the internal network.
* [terraform-dns-cloudflare](https://github.com/ibm-cloud-architecture/terraform-dns-cloudflare) - To create CNAME records on cloudflare to get to the console and applications from our external network.
* [terraform-certs-letsencrypt-cloudflare](https://github.com/ibm-cloud-architecture/terraform-certs-letsencrypt-cloudflare) - To generate certs from LetsEncrypt for our console and router
* [terraform-openshift3-deploy](https://github.com/ibm-cloud-architecture/terraform-openshift3-deploy) - To generate the ansible inventory file and deploy Openshift.

Before deploying, you will need to set the following environment variables:

```bash
export VSPHERE_USER=<user>
export VSPHERE_PASSWORD=<password>

export CLOUDFLARE_EMAIL=<cloudflare email>
export CLOUDFLARE_TOKEN=<cloudflare api key>
export CLOUDFLARE_API_KEY=<cloudflare api key>
```

Use the following commands to deploy:

```bash
terraform init
terraform apply 
```

## Example

Example `terraform.tfvars` file.  We provision an non-HA Openshift cluster.

```terraform
#######################################
##### vSphere Access Credentials ######
#######################################
vsphere_server = "my-vsphere-server.mydomain.com"

# Set username/password as environment variables VSPHERE_USER and VSPHERE_PASSWORD

# SSH username and private key to connect to VM template, has passwordless sudo access
ssh_user = "virtuser"
ssh_private_key_file = "~/.ssh/id_rsa"

##############################################
##### vSphere deployment specifications ######
##############################################
# Following resources must exist in vSphere
vsphere_datacenter = "dc01"
vsphere_cluster = "cluster01"
vsphere_resource_pool = "respool01"
datastore_cluster = "ds_cluster01"
template = "rhel-7.6-template"

# for the vsphere-standard storage class
vsphere_storage_username = "<storageuser>"
vsphere_storage_password = "<storagepassword>"
vsphere_storage_datastore = "ds01"


# vSphere Folder to provision the new VMs in, will be created
folder = "example"

# MUST consist of only lower case alphanumeric characters and '-'
hostname_prefix = "ocp-test"

# it's best to use a service account for these
image_registry_username = "<service_acct_username>"
image_registry_password = "<service_acct_token>"

rhn_poolid = "<poolid>"

##### Network #####
private_network_label = "private_network"
bastion_private_ip = ["192.168.0.10"]
master_private_ip = ["192.168.0.11"]
infra_private_ip = ["192.168.0.12"]
worker_private_ip = ["192.168.0.13", "192.168.0.14"]
storage_private_ip = ["192.168.0.15", "192.168.0.16", "192.168.0.17"]

private_netmask = "24"
private_gateway = "192.168.0.1"
private_domain = "my-private-domain.local"
private_dns_servers = [ "192.168.0.1" ]

# to stand up the registry a vssphere block volume
storage_class = "vsphere-standard" 

# manually added to DNS, the app_cname is a wildcard domain pointing at the infra node
master_cname = "ocp-master.my-private-domain.local"
app_cname = "ocp-app.my-private-domain.local"

bastion = {
    nodes               = "1"
    vcpu                = "2"
    memory              = "8192"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
}

master = {
    nodes                 = "1"
    vcpu                  = "8"
    memory                = "32768"
    disk_size             = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size      = "100"   # Specify size for docker disk, default 100.
    thin_provisioned      = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub         = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove   = "false" # Set to 'true' to not delete a disk on removal.
}

infra = {
    nodes               = "1"
    vcpu                = "8"
    memory              = "32768"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
}

worker = {
    nodes               = "2"
    vcpu                = "16"
    memory              = "32768"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
}

# each storage node has 2x 250GB volumes used to store data
storage = {
    nodes               = "3"
    vcpu                = "4"
    memory              = "8192"
    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    gluster_disk_size   = "250"
    gluster_num_disks   = 2
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
}
```
