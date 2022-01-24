# Add your Tanzu Network credentials here

export TANZUNET_USERNAME="<replace-this>"
export TANZUNET_PASSWORD="<replace-this>"

# Add your Calatrava namespace here

export CALATRAVA_NAMESPACE="<replace-this>"

# Add your container registry details here.
# The given REGISTRY value reflects a reasonable pattern for
# a TAP install on Harbor.
# Strictly the "registry" is the server, and that hosts multiple
# repositories but we stick with registry for consistency.

export REGISTRY_USERNAME="<replace-this>"
export REGISTRY_PASSWORD="<replace-this>"
export REGISTRY="harbor-repo.vmware.com/${REGISTRY_USERNAME}/tap"
export REGISTRY_SERVER="harbor-repo.vmware.com"
export REGISTRY_PATH="${REGISTRY_USERNAME}/tap"

###
### Don't change anything from here on ...
###

# TAP package registry information
export INSTALL_REGISTRY_USERNAME="${TANZUNET_USERNAME}"
export INSTALL_REGISTRY_PASSWORD="${TANZUNET_PASSWORD}"
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com

export DOMAIN="${CALATRAVA_NAMESPACE}.calatrava.vmware.com"