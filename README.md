# rhis-builder-satellite
The code in this repo builds the Satellite configuration for an RHIS deployment. Currently, this deployment assumes the Red Hat Infrastructure Standard Adoption Model is being followed and assumes that your Identity Manager instance has been deployed. If you do not have an Identity Manager instance for your RH-ISAM environment please see the rhis-builder-idm repo in this github first to deploy a Red Hat Identity Management server.

### What rhis-builder-satellite does

rhis-builder-satellite makes the following changes to a system installed with an @Base RHEL system build:
- ensures the system is registered directly to the CDN
- configures all Satellite prerequisites

### Deploying an RHIS Satellite environment.

As of this build, we do not deploy Capsule Servers. Coming Soon! TM

Clone the repo to your provisioning server.

Set sat_primary in the inventory to the FQDN of a @Base RHEL 8 build system (virtual, physical or prepared cloud image (non-RHUI)). 

Create a directory with for the FQDN of the sat_primary server under the host_vars directory. 
(e.g. rhis-builder-satellite/host_vars/rhissat.mydomain.com)

Copy the contents of the sat.example.ca directory in host_vars to the sat_primary directory in host_vars in the previous step.

Update the variables to suit your configuration.

NOTE: Almost all variable sets have the form of
config_name_rhisam:
  list

config_name_user:
  list

All the Red Hat Infrastructure Standard basic configuration is defined by the config_name_rhisam: entries. All provisioning parameters should be configured specifically for your environment (e.g. compute_resources). Use these for your first experimental run. It will create a functional environment. 

As your environment evolves, add your own config_name_user: elements to define the specifics. All sections should be properly tagged, so you can run or omit the sections of your choice.

Lastly configure your secrets. They are defined in rhisbuilder_vault.yml in the executing users home directory. This contains all the secrets for the rhis-builder series of repos.

Update the variables for rhisbuilder_vault.yml_SAMPLE file and save it in the home directory of the executing user on the provisioner machine as rhisbuilder_vault.yml. Encrypt it with ansible vault.

Run the main.yml playbook using your favourite ansible environment referencing your vault password file.  e.g.

```
ansible-playbook -i inventory main.yml --vault-password-file=/home/parmstro/.ansible/vault.txt
```
Wait a few hours depending on your pipe to the Red Hat CDN and horsepower of your system. They you will be able to log in to your Satellite.