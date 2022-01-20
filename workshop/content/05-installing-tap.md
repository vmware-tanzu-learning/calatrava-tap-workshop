Now you have your own cluster on Calatrava you can move on to
installing TAP.
This isn't hard, but there are just a few steps that you will
need to perform, which we will walk through here.

The full process for installing TAP is described in the
[official documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-intro.html).
Some of the steps, particularly downloading and installing
the Tanzu CLI and the prerequisite software has already been done
for you, so now it's just the steps that depend on having your
Kubernetes cluster available.

## Configure access to your cluster

Before doing anything else, you need to set your default Kubernetes
configuration to use your guest cluster.

```execute
export KUBECONFIG=~/terraform/gc.kubeconfig
```

## Install "Tanzu Cluster Essentials"

In your home directory you will find a sub-directory named
`tanzu-cluster-essentials`, so go there now.

```execute
cd ~/tanzu-cluster-essentials
```

There is a script in that directory, `install.sh` which you will
use to install some key packages needed to bootstrap everything else.
However, before you run that, you need to set up some environment
variables.
For two of those variables you will need to supply your Tanzu
Network username and password.

```copy-and-edit
# Add your credentials here

export INSTALL_REGISTRY_USERNAME=<tanzu-network-username>
export INSTALL_REGISTRY_PASSWORD=<tanzu-network-password>

# Don't change these

export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
```

Now you can run the install script.

```execute
./install.sh
```

## Add the TAP package repository

Once the install script has finished you can move on to adding
the TAP package repository to your cluster.
This, and a number of other components, belong in a namespace
called `tap-install`.
The repository needs to draw information from the Tanzu Network so a secret holding those is also needed.

So, the following sequence of commands will do those steps.

```execute
kubectl create ns tap-install

tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} \
  --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install

tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.0 \
  --namespace tap-install
```

That final command should finish with a message:

```
Added package repository 'tanzu-tap-repository'
```

You can check if it has complete successfully by running:

```execute
tanzu package repository get tanzu-tap-repository \
  --namespace tap-install
```

This should produce something like the following:

```
- Retrieving repository tap...
NAME:          tanzu-tap-repository
VERSION:       121657971
REPOSITORY:    registry.tanzu.vmware.com/tanzu-application-platform/tap-packages
TAG:           1.0.0
STATUS:        Reconcile succeeded
REASON:
```

If the status is still shown as "Reconciling" then wait for a minute
or two before checking again.