TAP on Calatrava
================

This workshop guides you through the process of installing Tanzu
Application Platform (TAP) on VMware's internal Calatrava environment.
At the end of the workshop you will have created a Kubernetes
cluster on Calatrava, with TAP installed on it.
You can then download the configuration files so that you can
use that cluster for experimentation and learning.

The workshop currently installs TAP version 1.1.0.

If you don't have access to VMware's internal network the workshop
won't be of any immediate use.
However, it would be relatively straightforward to adapt this to
work with another vSphere environment, or a public cloud such as AWS,
Azure or GCP.
Once a cluster has been provisioned, the steps of installing TAP are
very similar across all platforms.

## Building

The workshop uses a custom image with the Tanzu CLI, Terraform and
`kapp` and `ytt` pre-installed.
It also pre-downloads installation files from the Tanzu Network
site using the `pivnet` CLI tool.

```bash
export PIVNET_TOKEN="some-valid-tanzu-network-token"
export TAP_VERSION=1.1.0

docker build -t harbor-repo.vmware.com/nwinton/calatrava-tap-workshop:$TAP_VERSION \
  --no-cache --build-arg PIVNET_TOKEN .

docker push harbor-repo.vmware.com/nwinton/calatrava-tap-workshop:$TAP_VERSION
```

## Installation

On an existing TAP installation with Learning Center installed run
the following:

```
kubectl apply -f resources/workshop.yaml
kubectl apply -f resources/training-portal.yaml
```

This will deploy a training portal hosting just this workshop. To get the
URL for accessing the training portal run:

```
kubectl get trainingportal/calatrava-tap-workshop
```

The training portal is configured to allow anonymous access.
