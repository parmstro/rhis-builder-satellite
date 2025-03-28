# rhis-builder-satellite

Fork it. Clone it. Configure it. Test it. Change it. Commit it. Create a PR.

***
#### Helping out
I know that most of you have experience with these things, but we also work with people with less experience. So, please bear with us if a lot of items that you know are spelled out. If you have any comments, tips, tricks or suggestions to add to the documentation or README.md file, PRs are greatly appreciated. Let's share the wealth!

If you haven't been there yet, please visit the [rhis-builder-provisioner wiki](https://github.com/parmstro/rhis-builder-provisioner/wiki) first

***

Hey, welcome to the next repo on your way to building the RHIS.

The code in this repo builds the Satellite configuration for an RHIS deployment. Currently, this deployment assumes the Red Hat Infrastructure Standard Adoption Model is being followed. You can now deploy with or without Red Hat Identity Management integration. If you are following the RH-ISAM and **want** to have an Identity Management instance for your environment, please see the **[rhis-builder-idm](https://github.com/parmstro/rhis-builder-repo)** repo and build it before you deploy Satellite. 

If you do not want to deploy your Satellite integrated with an Identity Management instance, you must ensure that you provide for the related services for authentication, dns, certificates, etc.. within your configuration. You will need to set the satellite_pre_use_idm to false in your satellite_pre.yml variable file
e.g.
```
satellite_pre_use_idm: false
```
#### Note: this probably means you aren't using Realms anywhere unless they are AD realms, so check variable files referencing realms, like hostgroups, realms, etc..

#### If you are integrating with IdM and you don't want to regenerate the keytab file for your realm user (because you have capsules that are currently using it) set skip_prepare_realm below to true. This will avoid having to redistribute the keytab file to your capsules.
e.g.
```
skip_prepare_realm: true
```
### Be Prepared!

There is a mountain of configuration available for Satellite. The good news is that a whole lot of it is stuff that everyone typically wants to use in their environment. Repos and Content Views are big ones. You can trim down the repos that you want to deploy or build them out. The only limit is your disk space. We have put a lot of the basics in. If you are looking for additional repo configurations, look at the rhis-builder-satellite-content repository for addition samples you can add to your Satellite. These are vetted by the team. Any contributed repos need to supply content credentials (GPG key). 

It is probably best for your first run, to make as few changes to the sample configuration as possible, to get a feel. Then extend. If you have problems, please open an issue. 

## I'm in a hurry, let's just do it.

### What's new
* rhis-builder-satellite now configures user roles, groups and users. This supports external users and groups from IdM
* we got rid of the distinction between *_rhisam and *_user variable sets. Only one set now and all the examples are under satellite.example.ca  

The rhisam configuration defaults are included in the hostvars directory for satellite.example.ca
We have set this up so that you can keep the rhisam configurations and add your own configuration through *config_name*_user, see below.

### Deploying an RHIS Satellite environment.

As of this build, we do not deploy Capsule Servers. Coming Soon! TM

Basic Steps:
1. Set sat_primary in the inventory to the FQDN of a @Base RHEL 8 build system (virtual, physical or prepared cloud image (non-RHUI)).
2. Create a directory with for the FQDN of the sat_primary server under the host_vars directory. (e.g. rhis-builder-satellite/host_vars/rhissat.mydomain.com)
3. Copy the contents of the satellite.example.ca directory into your directory created in the previous step.
4. Update the inventory file and set [sat_primary] to the FQDN of your system that will become the satellite.
5. Update the variables to suit your configuration. For details on all the varibles see variable_notes.md
6. Configure your secrets. For details on secrets see rhis-builder-vault_SAMPLE.yml
7. Launch the main.yml playbook.

Please see the documentation for the underlying redhat.satellite collection modules if you are looking for a setting that is not in an example. We try to be thorough, but miss things sometimes.

Sync Plans example:
```
sync_plans:
  - name: "nightly_os"
    desc: "Nightly OS repo sync - 00:30"
    interval: "daily"
    sync_date: "{{ ansible_date_time.date }} 00:30:00"
    enabled: true
    organization: "{{ satellite_organization }}"
    location: "{{ satellite_location }}"

  - name: "nightly_infra"
    desc: "Nightly non-OS repo sync - 02:30"
    interval: "daily"
    sync_date: "{{ ansible_date_time.date }} 02:30:00"
    enabled: true
    organization: "{{ satellite_organization }}"
    location: "{{ satellite_location }}"

```
Code sections are tagged, so you can run or omit the sections of your choice. 

Additionally, playbooks are provided for you to run individual tasks, roles or role tasks on their own. These files allow you to specify additional vault and variable files at the command line. E.g. for files use:
  * -e "vault_path=/path/to/my/rhis-builder-vault.yml"
  * -e "vars_path=/path/to/my/extra_variables.yml"

For directories use:
  * -e "vault_dir=/path/to/my/vault/"
  * -e "vars_dir=/path/to/my/vars/"

Examples are shown below:

```
# This runs the task build_pxe_linux_defaults from the tasks directory
ansible-playbook -i inventory test_task.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_task_name=build_pxe_linux_defaults"

# This runs the role activation_keys to refresh your activation key configuration from your variables file
ansible-playbook -i inventory test_role.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_role_name=activation_keys"

# This runs the the specific task publish_cv_version from the role content_views to publish the content views defined in your variables file
ansible-playbook -i inventory test_role_task.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_role_name=content_views" -e "test_task_name=publish_cv_version"
```

## Secrets Management

Due to the number of environments a Satellite server touches, rhis-builder-satellite requires a lot of secrets. 

There is a sample file in the repo called rhis-builder-vault.yml_SAMPLE file that contains all the current secrets used by rhis-builder-satellite and other rhis-builder-* repositories. You can copy this file to the home directory of the executing user on the provisioner machine and rename it as rhis-builder-vault.yml or something similar. We recommend encrypting it with ansible vault. If you prefer to manage secrets in a more modular fashion, it is trivial to create multiple files to separate secrets. Like the run_role and run_task plays above, main.yml allows you to specify external variable files easily to include vaults or extra vars. Simply provide them at the commandline.

## Run main.yml

Run the main.yml playbook using your favourite ansible environment referencing your vault password file.  e.g.
```
ansible-playbook -i inventory main.yml --vault-password-file=/home/myusername/.ansible/vault.txt

# Add your own (vaulted) variable files
ansible-playbook -i inventory main.yml --vault-password-file=/home/myusername/.ansible/vault.txt --extra-vars "@some_encrypted_vault_file.yml"
```
Building Satellite from scratch does take time. The big time consumers are synchronizing with the CDN and content publication. The time to deploy varies. For smaller systems with limited pipe, expect a few hours. Deploying to a baremetal GEN5 i5 NUC with 4 cores and 32GB of RAM takes about 3 hours with 1GB download pipe and 1GB network. 

If all runs smoothly, you then will be able to log in to your Satellite and get to work! 

We are always looking for feedback, feature requests, bug reports (issues) and pull requests.


***
## Give me more details, I can take it!

### What rhis-builder-satellite does NOT do
rhis-builder-satellite configures most things in satellite, however, it currently does not do the following:
- rhis-builder-satellite does not manage building multiple organizations and locations simultaneously. You can set these up individually today using multiple runs. This is something we are working on.
- we don't provide examples for all the settings that you can configure. We are in the process of creating samples for this with the defaults.
- we don't configure reports.
- we don't configure the UI widgets, etc..
- we don't export facts
- we don't launch or schedule jobs yet
- we don't directly manage Satellite tasks or recurring logics
- we don't directly manage subscriptions (add subscription function)
- we don't manage content credentials (this is high on our priority list)
- we don't configure alternate content sources (this is high on our priority list)
- we don't configure host collections (this is high on our priority list)
- we don't setup template synchronization
- we can't configure SCAP policies (need FAM module written for SCAP policy)
- we don't configure Cloud Connector / Insights / obfiscation
- we don't configure HTTP proxies
- we don't configure LDAP auth sources (IdM does get configured)
- we don't configure bookmarks
- we don't configure web hooks

If you have a burning desire to contribute any of the above, PRs are welcome.
All other parts of Satellite should be handled by rhis-builder.

### What rhis-builder-satellite does

rhis-builder-satellite makes the following changes to a system installed with an @Base RHEL system build:
- ensures the system is registered directly to the CDN
- configures all Satellite prerequisites
- installs the binaries
- runs the installer with your defined configuration
- configures hammer
- can create a manifest on the portal and download it
- can install the manifest on the satellite
- can update an existing manifest
- configures the Red Hat repository sets
- configures custom products
- synchonizes the repositories (this takes time...)
- configures life cycle environment paths and environments
- configures and attaches synch plans
- configures content views, filters, filter rules, composite content views
- publishes and promotes content views and composite content views
- configures media, partition tables, provisioning templates, job templates, and operating systems
- configures activation keys
- configures domains, realms, subnets
- build PXE linux defaults
- configures compute resources, compute profiles and images
- configure virt-who and deploy configuration
- synch git repos and install ansible roles need on the Satellite
- configure SCAP Content, tailoring files
- configure hostgroups
- configure SCAP policy (stub - to do)
- configure discovery and discovery rules for bare metal
- configure global parameters
- configure all satellite settings
- configure user roles, groups and users, internal and external


Enjoy!

The rhis-builder team
