# terraform-openshift3-ibmcloud-vpc-example

End to end example of deploying Openshift 3 on IBM Cloud VPC. In this example we use the following sub-modules:

* [terraform-openshift3-infra-ibmcloud-vpc](https://github.ibm.com/jkwong/terraform-openshift3-infra-ibmcloud-vpc) - To create VMs on VMware.
* [terraform-openshift-rhnregister](https://github.com/ibm-cloud-architecture/terraform-openshift-rhnregister) - To register all VMs with Red Hat Network subscriptions.
* [terraform-dns-etc-hosts](https://github.com/ibm-cloud-architecture/terraform-dns-etc-hosts) - To hack DNS which we didn't have readily available, we generated an `/etc/hosts` file containing every node in the cluster and sync it to all nodes.
* [terraform-certs-letsencrypt-dns01](https://github.com/ibm-cloud-architecture/terraform-certs-letsencrypt-dns01) - To generate certs from letsencrypt using DNS01 challenge.
* [terraform-openshift3-deploy](https://github.com/ibm-cloud-architecture/terraform-openshift3-deploy) - To generate the ansible inventory file and deploy Openshift.

Before deploying, you will need to set the following environment variables:

```bash
export IC_API_KEY

export TF_VAR_rhn_username=<redhat username>
export TF_VAR_rhn_password=<redhat password>

export CLOUDFLARE_TOKEN=<cloudflare token>
export CLOUDFLARE_EMAIL=<cloudflare email>

```

Use the following commands to deploy:

```bash
terraform init
terraform apply 
```

## Example

Example `terraform.tfvars` file.  We provision an non-HA Openshift cluster.

```terraform

# MUST consist of only lower case alphanumeric characters and '-'
deployment = "ocp-test"

# it's best to use a service account for these
image_registry_username = "<service_acct_username>"
image_registry_password = "<service_acct_token>"

rhn_poolid = "<poolid>"

# to stand up the registry a vssphere block volume
storage_class = "glusterfs" 

# manually added to DNS, the app_cname is a wildcard domain pointing at the infra node
master_cname = "ocp-master.my-private-domain.local"
app_cname = "ocp-app.my-private-domain.local"
```
