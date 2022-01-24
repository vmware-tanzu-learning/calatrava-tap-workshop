Now you have your own cluster on Calatrava you can move on to
installing TAP.
This isn't hard, but there are just a few steps that you will
need to perform, which we will walk through here.

The full process for installing TAP is described in the
[official documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-intro.html).
Some of the steps, particularly downloading and installing
the Tanzu CLI and the prerequisite software have already been done
for you, so now it's just the steps that depend on having your
Kubernetes cluster available.

Before you go any further, however, there are a couple of things
you need to do.
The first is to set the `KUBECONFIG` environment variable so
that you can interact with your new cluster.

```execute
export KUBECONFIG=~/terraform/gc.kubeconfig
```

The second is to disable the restrictive pod security policy in
place on TKG-created clusters.
This is _not_ a good practice in general but is currently necessary
in order to install TAP.

```execute
kubectl create clusterrolebinding \
	default-tkg-admin-privileged-binding \
	--clusterrole=psp:vmware-system-privileged \
	--group=system:authenticated
```

Now you will use an (unofficial) all-in-one setup script that tries
to take care of handling most of the details of doing the installation.
You will just have to set up some environment variables.
If you are only interested in getting a working TAP environment,
and don't want to learn about or control the finer details of
the installation, then take this route.

## Download the scripts

The first step is to download the latest version of the scripts
from a public GitHub repository.
Clone the repository into the home directory.

```execute
cd $HOME

git clone https://github.com/ndwinton/tap-setup-scripts
```

## Configure the environment

Within the cloned `tap-setup-scripts` directory there is a file,
`envrc-template` which contains a set of environment variable
definitions.
Before running the script you will need to modify these to
reflect your configuration.
The first values you will need are your Tanzu Network
username and password, which you should supply as the
values of `TN_USERNAME` and `TN_PASSWORD`.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export TN_USERNAME=(.*)
isRegex: true
group: 1
```

Next you need supply the details of your container registry in the
`REGISTRY` variable.
If you are using your personal project within the internal
Harbor registry this might be something like `harbor-repo.vmware.com/your-username/tap`.
Note that you will need a sub-project name such as `tap` on
the end, but the actual name is unimportant.
The `REG_USERNAME` and `REG_PASSWORD` are your credentials for that
registry.

```editor:select-matching-text
file: ~/tap-setup-scripts/envrc-template
text: ^export REGISTRY=(.*)
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
The details of the difference between the different profiles
can be found in the
[official documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install.html).

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
text: ^export SUPPLY_CHAIN=(.*)
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

## Run the setup script

When you have made all of the changes to the `envrc-template` file
you need next to load those definitions into your environment.

Move into the `tap-setup-scripts` directory, and `source` the file:

```execute
cd ~/tap-setup-scripts

source ./envrc-template
```

Now you can run the setup script:

```execute
./setup-tap.sh
```

By default, the script will install the latest publicly available
release of TAP.
If you want to install a specific version you can add an extra
option of `--version <version-number>`.

The script is quite verbose and there will be a large amount of text
printed out initially relating to the options that you have set
via the environment variables.
If you omitted to set some of the variables then the script will
prompt you for values.

There are a few stages in the script where it will pause while
performing installation actions.
The first is when it reaches this stage:

```
### Downloading kapp + secretgen configuration bundle
```

If this fails, it's possible that you have not entered your Tanzu
Nework credentials correctly.

Next will come:

```
### Deploying kapp-controller
```

and then:

```
### Deploying secretgen-controller
```

They should output messages similar to this:

```
2:14:12PM: ---- waiting on 1 changes [11/12 done] ----
2:14:13PM: ongoing: reconcile deployment/secretgen-controller (apps/v1) namespace: secretgen-controller
2:14:13PM:  ^ Waiting for 1 unavailable replicas
2:14:13PM:  L ok: waiting on replicaset/secretgen-controller-67685b5d64 (apps/v1) namespace: secretgen-controller
2:14:13PM:  L ongoing: waiting on pod/secretgen-controller-67685b5d64-vq2cb (v1) namespace: secretgen-controller
2:14:13PM:     ^ Pending: ContainerCreating
2:14:29PM: ok: reconcile deployment/secretgen-controller (apps/v1) namespace: secretgen-controller
2:14:29PM: ---- applying complete [12/12 done] ----
2:14:29PM: ---- waiting complete [12/12 done] ----
```

If they appear to hang then it's likely that you missed the step
at the start of this page to disable the pod security policy.

Assuming that those stages succeed you will see a few more
steps relating to setting up the Tanzu package repository,
a listing of the available packages and then a message
of the form:

```
### Installing core TAP profile: light
```

This is now the core of the TAP installation.
You should then see something like the following, where it will
pause for a number of minutes while the installation proceeds.

```
>>> Running: tanzu package installed update --install tap -p tap.tanzu.vmware.com -v 1.0.0 -n tap-install --poll-timeout 30m -f tap-values.yaml
| Updating installed package 'tap' 
- Getting package install for 'tap' 
| Installing package 'tap' 
| Getting package metadata for 'tap.tanzu.vmware.com' 
| Creating service account 'tap-tap-install-sa' 
| Creating cluster admin role 'tap-tap-install-cluster-role' 
| Creating cluster role binding 'tap-tap-install-cluster-rolebinding' 
| Creating secret 'tap-tap-install-values' 
| Creating package resource 
- Waiting for 'PackageInstall' reconciliation for 'tap' 
/ 'PackageInstall' resource install status: Reconciling
```

Finally, you should see:

```
Updated installed package 'tap' in namespace 'tap-install'
- Retrieving installation details for tap... 
NAME:                    tap
PACKAGE-NAME:            tap.tanzu.vmware.com
PACKAGE-VERSION:         1.0.0
STATUS:                  Reconcile succeeded
CONDITIONS:              [{ReconcileSucceeded True  }]
USEFUL-ERROR-MESSAGE:    
```

If the status is `Reconcile succeeded` then the core package
installation has completed successfully, and the
script will proceed with the final parts of the setup.
However, it is not uncommon for this step to time out, particularly
on shared "best effort" environments.
If this happens then the best thing to do is to re-run the script,
but with an added option to skip the early parts which have
completely successfully already.
It is fine to do this multiple times if necessary.

```
./setup.sh --skip-init
```

Finally the script will print out some useful information
about the services that it has created, for example:

```
###
### Applications deployed in TAP will run at 10.216.52.135
### Please configure DNS for *.apps.nwinton-demotap.calatrava.vmware.com to map to 10.216.52.135
###
### The TAP GUI will run at http://gui.nwinton-demotap.calatrava.vmware.com:7000
### Please configure DNS for gui.nwinton-demotap.calatrava.vmware.com to map to 10.216.52.138
###
### App Accelerator is running at http://10.216.52.139
### (There is no need to configure DNS for this)
###

###
### To set up TAP services for use in a namespace run the following:
###

  kubectl apply -n YOUR-NAMESPACE -f /home/eduk8s/tap-setup-scripts/developer-namespace-setup.yaml
```

If the script runs this far then the installation is almost complete.
The script itself will make some final checks that all of the
installed packages are in the right state.
If they are not then you can wait a few minutes and check again
using:

```execute
tanzu package installed list -n tap-install
```

This should produce something like the following, with all packages
showing as having a status of `Reconcile succeeded`.
```
- Retrieving installed packages...
  NAME                       PACKAGE-NAME                                        PACKAGE-VERSION  STATUS
  accelerator                accelerator.apps.tanzu.vmware.com                   1.0.0            Reconcile succeeded
  api-portal                 api-portal.tanzu.vmware.com                         1.0.8            Reconcile succeeded
  
    ... many packages omitted ...

  tap                        tap.tanzu.vmware.com                                1.0.0            Reconcile succeeded
  tap-gui                    tap-gui.tanzu.vmware.com                            1.0.1            Reconcile succeeded
  tap-telemetry              tap-telemetry.tanzu.vmware.com                      0.1.2            Reconcile succeeded
  tekton-pipelines           tekton.tanzu.vmware.com                             0.30.0           Reconcile succeeded

```

## DNS Setup

DNS configuration for the system ingress is taken care of
automatically by Calatrava.
So, you should be able to access the following URLs

* `http://tap-gui.<namespace>.calatrava.vmware.com` for the TAP GUI
* `http://*.apps.<namespace>.calatrava.vmware.com` for deployed workloads
* `http://*.learn.<namespace>.calatrava.vmware.com` for Learning Center (if
you deployed it).

## Saving and modifying your configuration

Your TAP installation is now finished.
However, it's quite possible that you will want to modify
the configuration in future so before you leave this workshop
it is time to make a backup of your configuration.

As you may have seen, the installation script creates a number of
YAML files in the current directory.
There are files for each of the packages installed as part of
the overall TAP package.
However, the most important file is the `tap-values.yaml`.

You can make changes to your TAP installation by editing
this file and then reapplying it as follows (specifying whatever
version of the package is available at the time, here it is
`1.0.0`):

```
tanzu package installed update --install tap -p tap.tanzu.vmware.com -v 1.0.0 -n tap-install -f tap-values.yaml
```

You can always download the latest version of the setup scripts
from https://github.com/ndwinton/tap-setup-scripts but you will
probably want to save your `envrc-template` and `tap-values.yaml`
files.

```terminal:execute
command: cd ~/tap-setup-scripts && zip ~/tap-setup.zip envrc-template *.yaml
clear: true
session: 2
```

```files:download-file
path: tap-setup.zip
```

# Test your TAP installation

Congratulations!
Whichever path you took, you should now have a fully functioning TAP environment of your own on Calatrava to use and experiment with.

You can demonstrate this by visiting the TAP GUI which, if you've
taken the recommended settings in the setup, will be at
`http://tap-gui.<namespace>.calatrava.vmware.com`.

```execute
grep baseUrl: ~/tap/tap-values.yaml
```

Once you've done that it's time to move on to the final part
of this workshop.