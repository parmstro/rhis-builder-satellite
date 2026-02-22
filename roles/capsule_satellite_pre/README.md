### Capsule Satellite Prerequiste Readme

The initial creation of capsules starts with the Satellite.
All Capsule servers must be registered to the Satellite.
The default for rhis-builder is that the Capsule servers are deployed by the Satellite server in the target environment using the appropriate compute resource and compute profile.
This ensures that the systems are registered and have access to the proper repositories based on an activation key
The best way is to use the rhis-builder-pipeline project and your provisioner node to build the capsules from a satellite_capsule hostgroup.
Build the hosts.

After building the hosts you need to run the preparation activities on the satellite server.
This will generate custom certificates for the capsules, create the capsule certs tar file and the installation script for running the installation on the capsule servers.

After the capsule satellite preparation is done, you can continue to deploy and configure the capsule server software on all targets by call the capsules_main.yml playbook.
The playbook applies the following roles for each host listed in the inventory under sat_capsules:
- capsule_pre: this will perform all the mandatory prerequisite configurations and checks on the capsules
- capsule: this role copies the required certificates and scripts to the hosts and executes the script
- capsule_post: this performs the post installation configuration of the environment for the capsules
The playbook then ensures that the capsule synchronization process is started on all capsules.

