# NOTE: If your username or password contains ' or \ characters
# be careful to escape them properly when supplying values for
# the placeholders below.

# Add your Tanzu Network credentials here
export TANZUNET_USERNAME='<replace-this>'
export TANZUNET_PASSWORD='<replace-this>'

# Add your Calatrava namespace here, it will
# be something like 'yourvmwareid-tap'

export CALATRAVA_NAMESPACE='<replace-this>'

# Add your container registry details here.
# The given REGISTRY value reflects a reasonable pattern for
# a TAP install on Harbor.
# Strictly the "registry" is the server, and that hosts multiple
# repositories but we stick with the term registry for consistency.

export REGISTRY_USERNAME='<replace-this>'
export REGISTRY_PASSWORD='<replace-this>'
# The HARBOR_PROJECT may be the same as your username for
# personal repositories.
export HARBOR_PROJECT='<replace-this>'
export REGISTRY="harbor-repo.vmware.com/${HARBOR_PROJECT}/tap"
export REGISTRY_SERVER="harbor-repo.vmware.com"
export REGISTRY_PATH="${HARBOR_PROJECT}/tap"
# For DockerHub use these values ...
#export REGISTRY="index.docker.io/${REGISTRY_USERNAME}/tap"
#export REGISTRY_SERVER="index.docker.io"
#export REGISTRY_PATH="${REGISTRY_USERNAME}"

###
### Don't change anything from here on ...
###

# TAP package registry information
export TAP_VERSION=1.1.0
export INSTALL_REGISTRY_USERNAME="${TANZUNET_USERNAME}"
export INSTALL_REGISTRY_PASSWORD="${TANZUNET_PASSWORD}"
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:ab0a3539da241a6ea59c75c0743e9058511d7c56312ea3906178ec0f3491f51d
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com

export DOMAIN="${CALATRAVA_NAMESPACE}.calatrava.vmware.com"