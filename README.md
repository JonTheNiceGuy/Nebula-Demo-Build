# Overlay Networks Research
## Why look at Overlay Networks?

Overlay networks provide a way of "layering" a second, virtual, IP network over the top of your existing physical IP network. A
good, and regularly used example of this is in a VPN network for remote or home workers, where they receive a "second" IP
address on the VPN interface that allows them access to their work resources. People who don't have access to this second
network can't access the resources on the work network.

These VPNs typically use IPsec tunnel, [AnyConnect](http://www.cisco.com/go/asm).
[OpenConnect](https://tools.ietf.org/html/draft-mavrogiannopoulos-openconnect-02),
[Pulse Connect Secure](https://www.pulsesecure.net/products/connect-secure/),
[Palo Alto GlobalProtect SSL VPN](https://www.paloaltonetworks.com/features/vpn),
[Microsoft SSTP](https://msdn.microsoft.com/en-us/library/cc247338.aspx) or other VPN products.

A [recent announcement](https://slack.engineering/introducing-nebula-the-open-source-global-overlay-network-from-slack-884110a5579)
from SlackHQ about their "[Nebula](https://github.com/slackhq/nebula)" product, and the first response to that post referencing
[ZeroTier](https://www.zerotier.com/)'s product [ZeroTierOne](https://github.com/zerotier/ZeroTierOne) triggered some interest
in me, in particular because these specific overlay networks provide secured access to resources. Nebula and ZeroTier have
clients for all major Desktop and Server OS platforms. Nebula also has an iOS client in the works, while ZeroTier has both
Android and iOS clients available today. Nebula and ZeroTier also have in-built packet filtering capabilities.

Docker Swarm has overlay network products too, but I'm not sure how these would compare, or if they would at all.

## What is this particular repository testing?

This repository will be testing Nebula using Ansible Tower (AWX) Management. In particular, it looks to test the following:

1. How easy is any server or management portion to set up?
2. How easy is any client portion to set up?
3. How quickly can management changes be pushed to clients?
4. How performant is the VPN once it's established?

## What is in this repository?

There are three directories:

* [Terraform](Terraform) - This directory contains all the code to provision at least the AWX server and the Nebula CA Server.
  * Note that in here are three .gitignore'd files - `admin_password` which contains the password for your AWX environment, `id_rsa.pub` the SSH public key for all your VMs and `vaultfile` which contains the ansible-vault passphrase.
* [AWX Install and Manage](AWX_Install_And_Manage) - This directory contains the code to install the AWX service, including provisioning:
  * AWX User ("Nebula_Provisioning") - Unused
  * AWX Organisation ("NebulaOrg")
  * AWX Team ("NebulaProvisioner") - Unused
  * AWX Credentials (encrypted with Ansible-Vault)
    * AWS Token/Secret "Nebula AWS" - to get the inventory list from AWS
    * Azure Client/Secret/Subscription/Tenant "Nebula Azure" - to get the inventory list from Azure
    * SSH Keys "Default Machine" - to SSH into the appliances
    * Ansible-Vault Key (encrypted with Ansible-Vault) - to decrypt any subsequent values we create
  * AWX Project ("Ansible Managed Nebula") - The path to the Git repo.
  * AWX Inventories ("NebulaEC2", "NebulaAzure") - a list of assets.
  * AWX Job Template ("Nebula EC2")
* [Nebula Install and Manage](Nebula_Install_And_Manage) - This directory delivers the Nebula binaries, creates certificates and configuration files, then starts the associated services.

## What isn't in this repository that you'll have to re-create?

* The admin password for AWX - I tend to use a string like: YYYYMMDD_Environment (e.g. `20191219_Awx`) - this needs to be stored in `Terraform/admin_password`.
* The Ansible Vault password, used to decrypt the secrets for [AWX Install and Manage](AWX_Install_And_Manage) and
[Nebula Install and Manage](Nebula_Install_And_Manage). It should also be stored in `AWX_Install_And_Manage/secrets.yml` as
the VAULT variable.
* The SSH key you'll use to SSH into your nodes. Store in the following places:
  * Public Key:
    * `Terraform/id_rsa.pub`
    * `Nebula_Install_And_Manage/roles/deliver_bastion/files/id_rsa.pub`
  * Private Key:
    * `Nebula_Install_And_Manage/roles/deliver_bastion/templates/id_rsa` - encrypted with Ansible-Vault
    * `AWX_Install_And_Manage/secrets.yml` - base64 encoded, and stored in the SSH_KEY variable
* The AWS token and secret. Store this in `AWX_Install_And_Manage/secrets.yml` as variables AWS_TOKEN and AWS_SECRET.
* The Azure client, secret, subscription and tenant. Store this in `AWX_Install_And_Manage/secrets.yml` as variables
AZURE_CLIENT_ID, AZURE_SECRET, AZURE_SUBSCRIPTION_ID and AZURE_TENANT.

## What will this provision?

1. In AWS, A management Virtual Network, nMgmt1 with two subnets sMgmt1_Public (198.18.1.0/24) and sMgmt2_Private (198.18.2.0/24).
2. In AWS, A Server Virtual Network, nWeb1 with two subnets sWeb1_Public (198.18.3.0/24) and sWeb1_Private (198.18.4.0/24).
3. In Azure, A Server Virtual Network, nWeb2 with two subnets sWeb2_Public (198.18.5.0/24) and sWeb2_Private (198.18.6.0/24).
4. A collection of trusted machines:
  1. iMgmt1_awx in sMgmt1_Public with an Elastic IP, running AWX (Ansible Tower's open source version), addressable as "https://awx.<elastic_ip>.nip.io"
  2. iMgmt1_nebulaca in sMgmt1_Private
  3. iWeb1_bastion in sWeb1_Public with an Elastic IP, accessible ONLY to AWX over SSH
  4. iWeb1_web in sWeb1_Public with an Elastic IP, exposing only HTTP and HTTPS on the Public IP
  5. iWeb1_database in sWeb1_Private.
  6. iWeb2_bastion in sWeb2_Public with a Public IP, accessible ONLY to AWX over SSH
  7. iWeb2_web in sWeb2_Public with a Public IP, exposing only HTTP and HTTPS on the Public IP
  8. iWeb2_database in sWeb2_Private.

After building, iMgmt1_awx will be configured (using the scripts in [AWX Install and Manage](AWX_Install_And_Manage))
with credentials for AWS, SSH keys and Vault credentials (basically so I can share the SSH keys I used to build this
script). It also adds the users, organisations, "projects" (another name for git repos), and "job templates"
(activities to be executed) which are listed in `AWX_Install_And_Manage/run.json`.

There is a chance that the Vault credential won't be added to the job templates, so if this is the case for you, the first run
of the job template won't succeed. If this is the case for you, edit the job template to add the vault credential, and then
re-run the job.

This will then add the SSH key to each bastion host, and SSH to each of them to provision the Nebula client. It'll also generate
a per-machine key on the Nebula CA host, and distribute those to all the machines.

The script makes extensive use of AWS tagging, using tags like `"Nebula_lighthouse = true"` and `"Nebula_ip = 198.19.1.1/24"`
as well as the security groups to apply actions to each of the nodes. I'm not exactly sure what would happen if overlapping
Nebula tags are applied! It also uses the `"OS = ubuntu"` tag to work out what credentials to use, and
`"Bastion_ip = 192.0.2.1"` to work out whether to connect over SSH via a Bastion, or not.