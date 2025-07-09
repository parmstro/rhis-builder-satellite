## To Do List

### Fixes
- add code to discover and disable RHUI repos and extensions for cloud instances.

### Features 

- capsule-build role - build a satellite capsule using a hostgroup 
- capsule-pre role - install and configure the prerequisites for capsule
- capsule role - install the capsule server
- capsule-configure role - configure the capsule content, location, organization, alternate content source
- capsule-sync task

# Windows DNS DHCP https://access.redhat.com/solutions/4236381
# requirements Bryndis Swan (github:TurtlesRock)(forces.gc.ca)
# After reading the article, I think that the satellite server has to join the AD Realm

# Add code for disconnected deployment
#   - copy iso (maybe)
#   - validate of DVD/iso present
#   - configure repo file for DVD/iso
#   - validate repo
#   - part 1 - install
#   - part 2 - content ingest
#     - library content
#     - git repos / ansible collections
#   - part 2 - post content config

# see provisioner for other tasks related to collections and other content.
