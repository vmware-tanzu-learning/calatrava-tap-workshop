
# Local Tanzu CLI installation

Before you can use TAP to the full, you will need to have the
Tanzu CLI (the `tanzu` command binary) installed on your local
development system.
If you do not already have an up to date version installed, you
should follow the instructions for your operating system from the
[official documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-install-tanzu-cli.html).

Once you have this installed you can use it along with your
`tap-values.yaml` file to make further changes to your TAP installation,
if you wish.
You will also use it to create and manage workloads on TAP.

# Installing Tanzu Dev Tools for VSCode

An optional part of the overall TAP installation process is
to install some tooling for the VSCode IDE which makes working with
TAP easier.
The
[instructions](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-vscode-extension-installation.html)
are straightforward if you wish to use this, but it is not necessary
to do so in order to use TAP.

# Installing Terraform

If you want to make further changes to your Calatrava cluster,
and especially if you want to delete the cluster once you have
finished with it, you will need Terraform, and the `tap.tf` and
`terraform.tfstate` files that you should have saved earlier.
You can download the Terraform CLI from
https://www.terraform.io/downloads.

## To make changes to the cluster or to obtain new credentials

In the directory holding the `tap.tf` and `terraform.tfstate` files:

```
terraform init  # if not already done

terraform apply
```

## To delete the cluster

```
terraform init  # if not already done

terraform destroy
```
