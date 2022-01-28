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

Now you will follow the official installation instructions.
In order to keep things as straightforward as possible, this workshop
is going to make some simplifying assumptions, which will be
described at appropriate points.

If those assumptions do not meet your needs then you will have to make
the necessary adjustments as you go through the documentation.

## Part I: Prerequisites

The installation instructions are broken down into two main sections.
In order to avoid repeating things unnecessarily here, you will need
to keep the appropriate part of the documentation open, so open
the first part now:

```dashboard:open-url
url: https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html
```
This deals with setting up some pre-requisites, accepting EULAs
and installing the Tanzu CLI.
Some parts of this have already been done for you in this workshop environment and, as a VMware employee you should not have to
accept the EULAs.

### Prerequisites

Please read through the _Prerequisites_ section.
Some particular points to note are:

* _DNS Records_ will be taken care of by Calatrava and specific details
of how to configure this will be described later.
* For the _Tanzu Application Platform GUI_ this workshop will assume
that you are using a publicly accessible Git respository for your
catalog, and an in-memory database.
* The Calatrava cluster is created using TKG, which is not (at the time
of writing) officially supported according to the _Kubernetes cluster
requirements_.
It does, however, work.
* Strictly, the Calatrava configuration provisioned earlier in
this workshop does not have the 70GB of disk described in
the _Resource requirements_.
You can increase this if necessary, depending on how long-lived you
wish your cluster to be.

### Accept the EULAs

The _Accept the EULAs_ section should be irrelevant for VMware
employees, as acceptance happens automatically at download.
However, you can go through the process if you wish to understand
the customer experience.

### Install Cluster Essentials for VMware Tanzu

In the _Install Cluster Essentials for VMware Tanzu_ section some
of the work has already been done for you in the workshop environment.
The archive file has already been downloaded and expanded into
`tanzu-cluster-essentials` in your your home directory, and the `kapp`
tool is already installed.
This means that you only need to execute step 4.

As you are going to need to set up several other environment variables
during the installation process, in addition to the ones shown in this
step, this workshop assumes that you will put them all in a single
definition file.
You will find a suitable file in `~/tap/environment.sh`, which you
should edit now.

```editor:select-matching-text
file: ~/tap/environment.sh
text: (<replace-this>)
isRegex: true
group: 1
```

When you have saved that, you should load it into your current
session:

```execute
source ~/tap/environment.sh
```

Now you can run the cluster essentials install script:

```execute
cd $HOME/tanzu-cluster-essentials

./install.sh
```

### Install or update the Tanzu CLI and plug-ins

The `tanzu` CLI has already been installed in the workshop environment
and there is nothing to do.
You will, however, need to install the CLI on your local machine
before you can use TAP from there.

## Part II: Profiles

Now you can move on to the main part of the installation process.

```dashboard:open-url
url: https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install.html
```

### Add the Tanzu Application Platform package repository

You should follow through the steps of this process to configure
the TAP package repository.
For convenience, the commands are reproduced here, but please
follow through the documentation to understand what they are
doing, and that they still match the current versions.

Create the `tap-install` namespace:

```execute
kubectl create ns tap-install
```

Create a registry secret:

```execute
tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} \
  --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install
```

Add the TAP package repository:

```execute
tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.0 \
  --namespace tap-install
```

Check the status of the repository:

```execute
tanzu package repository get tanzu-tap-repository --namespace tap-install
```

List the available packages:

```execute
tanzu package available list --namespace tap-install
```

### Install a Tanzu Application Platform profile

Unless you particularly want to explore the Learning Center or
the security tools, you will probably want to choose the `light`
profile to install.

A crucial part of the process is to create a `tap-values.yaml` file.
Assuming that you have set the variables in the `environment.sh`
file, you can create a file suitable for a `light` installation
on Calatrava by doing the following:

```execute
cd ~/tap

envsubst < tap-values.yaml.template > tap-values.yaml
```

You should then edit the file to make sure that you are happy with
the values that it has supplied.

```editor:open-file
file: ~/tap/tap-values.yaml
```

In particular, the `tap_gui.app_config.catalog` value points to
a blank catalog which you are welcome to use just to get the interface
up and running, but which you will probably want to replace with
a version of your own.
Also, the OOTB `basic` supply chain is the one selected, although
you can, of course, change this.

Unless you change them, the set of URLs that will be exposed by the
installation are as follows:

* `http://*.apps.<namespace>.calatrava.vmware.com` for deployed workloads
* `http://tap-gui.<namespace>.calatrava.vmware.com` for the TAP GUI
* `http://*.learn.<namespace>.calatrava.vmware.com` for Learning Center (if
you deploy it).

(Note that all of these are unsecured, HTTP-only endpoints.)

Once you have your `tap-values.yaml` file you can start the
package installation, as it describes in the documentation:

```execute
cd ~/tap

tanzu package install tap -p tap.tanzu.vmware.com -v 1.0.0 \
  --values-file tap-values.yaml -n tap-install
```

If the command times out, as may happen, it is safe to re-run it.
Once it has completed you can run:

```execute
tanzu package installed get tap -n tap-install
```

Followed by:

```execute
tanzu package installed list -A
```

### Set up developer namespaces

It is easy to miss this step as it it linked out from the text
after the package installation.
However, before you can use TAP to create any workloads you
must follow the steps to
[set up developer namespaces](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-components.html#setup).

Using the values provided in `environment.sh`, here are
a set of commands to set this up for the `default` Kubernetes namespace.
Note that the first command is slightly different depending on
whether you used DockerHub for your container registry.

#### If you are _NOT_ using DockerHub for your registry

```execute
tanzu secret registry add registry-credentials \
  --server "${REGISTRY_SERVER}" \
  --username "${REGISTRY_USERNAME}" \
  --password "${REGISTRY_PASSWORD}" \
  --namespace default
```

#### If you _ARE_ using DockerHub for your container registry

```execute
tanzu secret registry add registry-credentials \
  --server "https://index.docker.io/v1/" \
  --username "${REGISTRY_USERNAME}" \
  --password "${REGISTRY_PASSWORD}" \
  --namespace default
```

In either case, you should then follow this with the following:

```execute
cat <<EOF | kubectl -n default apply -f -

apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: tap-registry

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: default
rules:
- apiGroups: [source.toolkit.fluxcd.io]
  resources: [gitrepositories]
  verbs: ['*']
- apiGroups: [source.apps.tanzu.vmware.com]
  resources: [imagerepositories]
  verbs: ['*']
- apiGroups: [carto.run]
  resources: [deliverables, runnables]
  verbs: ['*']
- apiGroups: [kpack.io]
  resources: [images]
  verbs: ['*']
- apiGroups: [conventions.apps.tanzu.vmware.com]
  resources: [podintents]
  verbs: ['*']
- apiGroups: [""]
  resources: ['configmaps']
  verbs: ['*']
- apiGroups: [""]
  resources: ['pods']
  verbs: ['list']
- apiGroups: [tekton.dev]
  resources: [taskruns, pipelineruns]
  verbs: ['*']
- apiGroups: [tekton.dev]
  resources: [pipelines]
  verbs: ['list']
- apiGroups: [kappctrl.k14s.io]
  resources: [apps]
  verbs: ['*']
- apiGroups: [serving.knative.dev]
  resources: ['services']
  verbs: ['*']
- apiGroups: [servicebinding.io]
  resources: ['servicebindings']
  verbs: ['*']
- apiGroups: [services.apps.tanzu.vmware.com]
  resources: ['resourceclaims']
  verbs: ['*']
- apiGroups: [scanning.apps.tanzu.vmware.com]
  resources: ['imagescans', 'sourcescans']
  verbs: ['*']

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: default
subjects:
  - kind: ServiceAccount
    name: default

EOF
```

### Configure LoadBalancer for Contour ingress

If you used the template `tap-values.yaml` file supplied above
then this will have been taken care of.

### Access the Tanzu Application Platform GUI

Again, if you used the template configuration file, the GUI will have
been set up using the "Ingress Method" described in the
[Accessing Tanzu Application Platform GUI](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-tap-gui-accessing-tap-gui.html)
documentation page.
There should be nothing more for you to do.

## Test your TAP installation

Congratulations!
You should now have a fully functioning TAP environment of your own on Calatrava to use and experiment with.

You can demonstrate this by visiting the TAP GUI which, if you've
taken the recommended settings in the setup, will be at
`http://tap-gui.<namespace>.calatrava.vmware.com`.

You can see the actual value by using this command:

```execute
grep baseUrl: ~/tap/tap-values.yaml
```

## OPTIONAL: Securing with a self-signed certificate

```section:begin
name: https
title: Securing with a self-signed certificate
```

You can exercise all of the TAP functionality over unsecured, HTTP
connections.
However, you may wish to add HTTPS support to your installation.
The following instructions will take you through the process of
creating self-signed certificates and adding those to TAP.

### Creating the certificate

There is a script in the `~/tap` directory that you can use to
create the necessary files.
If you already have the `DOMAIN` environment variable defined
(which you should have from previous steps) the all you need to
do is to run the following commands:

```execute
cd ~/tap

./create-tap-cert.sh
```

This will create several files, which are:

* `<domain-name>.key`: the private key file
* `<domain-name>.crt` : the certificate file
* `<domain-name>.csr` : the certificate signing request file
* `<domain-name>.config` : the OpenSLL config file used

### Configuring the system ingress

You need to add the key and certificate files as a secret in
the `tanzu-system-ingress` namespace:

```execute
kubectl create secret tls ingress-cert -n tanzu-system-ingress \
  --key ~/tap/$DOMAIN.key --cert ~/tap/$DOMAIN.crt
```

Then you need to configure Contour to use the secret:

```execute
kubectl apply -f - <<EOF
apiVersion: projectcontour.io/v1
kind: TLSCertificateDelegation
metadata:
  name: contour-delegation
  namespace: tanzu-system-ingress
spec:
  delegations:
    - secretName: ingress-cert
      targetNamespaces:
        - "*"
EOF
```

### Update TAP to use HTTPS

Now you will need to re-configure your TAP installation to
use HTTPS.
There are a number of options that need to be added or changed in
the `tap-values.yaml` file.
You can generate a new version of that, containing these settings
by running the command shown below.
Note that this will _overwrite_ any changes that you may previously
have made to that file so you may want to check it afterwards.

```execute
envsubst < ~/tap/https-tap-values.yaml.template > ~/tap/tap-values.yaml
```

Once you have done that you can can update your TAP installation:

```execute
tanzu package installed update tap -n tap-install -f ~/tap/tap-values.yaml
```

It may take a while for all of the packages to reconcile, but
once they have done so you should have an installation secured
with HTTPS.

### Using an officially signed certificate

Ideally, you should use certificates signed by a recognised certificate
authority.
The overall situation with SSL/TLS certificates in Calatrava is
described in
[this document](https://gitlab.eng.vmware.com/calatrava/calatrava/-/blob/master/docs/dns-and-certs.md#ssltls-certificates).

You can use HelpNow to request certificates for internal (and public)
use.
TAP needs to use certificates with "wildcards" in order to handle the
DNS names dynamically created to expose workloads.
While there are tight restrictions (for good security reasons) on
public certificates with widlcards, it is acceptable to employ
such certificates for internal use.

You can use the CSR file generated by the script to request an
internal-only certificate.
You can then update your TAP installation to use this.

```section:end
name: https
```

# Saving and modifying your configuration

You can make changes to your TAP installation by editing
your `tap-values.yaml` file and then reapplying it at some time
in the future using the `tanzu package installed update` command.
However, this means that you should keep that file (and others
that you may have generated) safe.

```terminal:execute
command: cd ~/tap && zip ~/tap-config.zip *
clear: true
session: 2
```

```files:download-file
path: ~/tap-config.zip
```

Once you've done that it's time to move on to the final part
of this workshop.