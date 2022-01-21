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

You now have two paths you can follow.

The first uses an (unofficial) all-in-one setup script that tries
to take care of handling most of the details of doing the installation.
You will just have to set up some environment variables.
If you are just interested in getting a working TAP environment
and don't want to learn about or control the finer details of
the installation then take this route.

The second path will take you through the official installation
documentation.
This is not difficult but will involve more steps and choices.

## The [Blue Pill](https://en.wikipedia.org/wiki/Red_pill_and_blue_pill): Unofficial set-up script

```section:begin
title: I just want to get it installed quickly
```

### Download the scripts

The first step is to download the latest version of the scripts
from a public GitHub repository.
Clone the repository into the home directory.

```execute
cd $HOME

git clone https://github.com/ndwinton/tap-setup-scripts
```

### Configure the environment

Within the cloned `tap-setup-scripts` directory there is a file,
`envrc-template` which contains a set of environment variable
definitions.
Before running the script you will need to modify these to
reflect your configuration.
The first values you will need are your Tanzu Network
username and password, which you will need to supply as the
values of `TN_USERNAME` and `TN_PASSWORD`.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export TN_.*=(.*)
isRegex: true
group: 1
```

Next you need supply the details of your container registry in the
`REGISTRY` variable.
If you are using your personal project within the internal
Harbor registry this might be something like `harbor-repo.vmware.com/your-username/tap`.
The `REG_USERNAME` and `REG_PASSWORD` are your credentials for that
registry.

```section:end
```

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export REG.*=(.*)
isRegex: true
group: 1
```

The next variable to change is the `INSTALL_PROFILE`.
If you want a full TAP installation with all of the components
then choose `full` as the value.
However, unless you particularly want to experiment with the
Supply Chain Security Tools, or the Learning Center (used to
create this workshop) then `light` will give you a quicker
and less resource-intensive installation.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export INSTALL_PROFILE=(.*)
isRegex: true
group: 1
```

Similarly, you can choose which supply chains to install.
The default combination of `basic` and `testing` is a reasonable
one to start with.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export .*SUPPLY_CHAIN=(.*)
isRegex: true
group: 1
```

Next you need to set the DNS domain through which your TAP
installation will be exposed.
On Calatrava a DNS domain will have been created for your namespace
of the form `<your-namespace>.calatrava.vmware.com`, so that is what
you should use.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export DOMAIN=(.*)
isRegex: true
group: 1
```

Finally, you need to supply a URL for a
[catalog file](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-tap-gui-catalog-catalog-operations.html)
for the TAP GUI.
If you don't have one already, you can use the following blank
catalog definition:

```copy
https://github.com/ndwinton/tap-gui-blank-catalog/blob/main/catalog-info.yaml
```

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export GUI_CATALOG_URL=(.*)
isRegex: true
group: 1
```

### Running the setup script

When you have made all of the changes to the `envrc-template` file
you need next to load those definition into your environment.

Move into the `tap-setup-scripts` directory, and `source` the file:

```execute
cd ~/tap-setup-scripts

source ./envrc-template
```

Now you can run the setup script:

```execute
KUBECONFIG=~/terraform/gc.kubeconfig ./setup-tap.sh
```

## The [Red Pill](https://www.youtube.com/watch?v=zE7PKRjrid4): Official installation documentation

```section:begin
title: Walk me through the install process
```

## Setting up environment variables

```editor:select-matching-text
file: ~/tap/environment.sh
text: (<tanzu-network-.*>)
isRegex: true
group: 1
```

## Configure access to your cluster

Before doing anything else, you need to set your default Kubernetes
configuration to use your guest cluster.

```execute
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