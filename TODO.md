## To Do List

### Fixes
- add code to discover and disable RHUI repos and extensions for cloud instances.

### Features 

# Capsule content implementation complete
# Next: (much of this may be innate)
#   - capsule baremetal host discovery
#   - capsule provisioning
#   - capsule remote execution

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

# Add keycloak integration to satellite
