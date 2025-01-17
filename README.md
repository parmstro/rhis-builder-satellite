# rhis-builder-satellite
The code in this repo builds the Satellite configuration for an RHIS deployment. Currently, this deployment assumes the Red Hat Infrastructure Standard Adoption Model is being followed and assumes that your Red Hat Identity Management instance has been deployed. If you are following the RH-ISAM and do not have an Identity Management instance for your environment configured yet, please see the rhis-builder-idm repo in this github. You can use the code in the repo to deploy a Red Hat Identity Management server quickly. 

If you do not want to deploy your Satellite integrated with an Identity Management instance, you must ensure that you provide for the related services for authentication, dns, certificates, etc.. within your configuration. We are working on a skip_ipa flag that will configure the Satellite in an IdM-independent way. This is one of our top priorities. We will update this message when complete and tested. For now, you will need to comment out a few lines of code in the satellite_pre role (everything after task 5 that installs the binaries).

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
- we don't configure roles
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

The rhisam configuration defaults are included in the hostvars directory for satellite.example.ca
We have set this up so that you can keep the rhisam configurations and add your own configuration through *config_name*_user, see below.

### Deploying an RHIS Satellite environment.

As of this build, we do not deploy Capsule Servers. Coming Soon! TM

Basic Steps:
1. Clone the repo to your provisioning server.
2. Set sat_primary in the inventory to the FQDN of a @Base RHEL 8 build system (virtual, physical or prepared cloud image (non-RHUI)).
3. Create a directory with for the FQDN of the sat_primary server under the host_vars directory. (e.g. rhis-builder-satellite/host_vars/rhissat.mydomain.com)
4. Copy the contents of the satellite.example.ca directory into your directory created in the previous step.
5. Update the inventory file and set [sat_primary] to the FQDN of your system that will become the satellite.
6. Update the variables to suit your configuration.
7. Configure your secrets.
8. Launch the main.yml playbook.



NOTE: All variable sets have the form of *config_name*_rhisam and *config_name*_user as in the example below. This should allow you to create a working environment at the outset. You can extend it by copying and pasting *_rhisam configurations to *_user configurations and modifying them appropriately. Please see the documentation for the underlying redhat.satellite collection modules if you are looking for a setting that is not in an example. We try to be thorough, but miss things sometimes.

Sync Plans example:
```
sync_plans_rhisam:
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

sync_plans_user:
  - name: "nightly_third_party"
    desc: "Nightly non-OS repo sync - 03:30"
    interval: "daily"
    sync_date: "{{ ansible_date_time.date }} 03:30:00"
    enabled: true
    organization: "{{ satellite_organization }}"
    location: "{{ satellite_location }}"

```
As your environment evolves, add your own config_name_user: elements to define the specifics. Code sections are tagged, so you can run or omit the sections of your choice. Additionally, playbooks are provided for you to run individual tasks, roles or role tasks on their own. This is equally suitableExamples are shown below:

```
# This runs the task build_pxe_linux_defaults from the tasks directory
ansible-playbook -i inventory test_task.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_task_name=build_pxe_linux_defaults"

# This runs the role activation_keys to refresh your activation key configuration from your variables file
ansible-playbook -i inventory test_role.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_role_name=activation_keys"

# This runs the the specific task publish_cv_version from the role content_views to publish the content views defined in your variables file
ansible-playbook -i inventory test_role_task.yml --vault-password-file=/home/myusername/.ansible/vault.txt -e "test_role_name=content_views" -e "test_task_name=publish_cv_version"
```

Due to the number of environments a Satellite server touches, rhis-builder-satellite requires a lot of secrets. 
The main playbooks currently look for a file called *rhisbuilder_vault.yml* defined in the home directory of the user that launches the playbook. There is a sample file in the repo called rhisbuilder_vault.yml_SAMPLE file that contains all the current secrets used by rhis-builder-satellite and other rhis-builder-* repositories. You can copy this file to the home directory of the executing user on the provisioner machine and rename it as rhisbuilder_vault.yml. We recommend encrypting it with ansible vault. If you prefer to manage secrets in a more modular fashion, it is trivial to create multiple files to separate secrets. You can edit the main.yml playbook to add your files or simply provide them at the commandline.

Run the main.yml playbook using your favourite ansible environment referencing your vault password file.  e.g.
```
ansible-playbook -i inventory main.yml --vault-password-file=/home/myusername/.ansible/vault.txt

# Add your own (vaulted) variable files
ansible-playbook -i inventory main.yml --vault-password-file=/home/myusername/.ansible/vault.txt --extra-vars "@some_encrypted_vault_file.yml"
```
Building Satellite from scratch does take time. The big time consumers are synchronizing with the CDN and content publication. The time to deploy varies. For smaller systems with limited pipe, expect a few hours. Deploying to a baremetal GEN5 i5 NUC with 4 cores and 32GB of RAM takes about 3 hours with 1GB download pipe and 1GB network. 

If all runs smoothly, you then will be able to log in to your Satellite and get to work! 

We are always looking for feedback, feature requests, bug reports (issues) and pull requests.

Enjoy!

The rhis-builder team
