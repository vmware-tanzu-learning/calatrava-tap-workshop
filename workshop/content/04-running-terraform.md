If you are not already in the `terraform` sub-directory, move there
now.

```execute
cd ~/terraform
```

There are three simple steps that you will take to create the cluster.
The first is to initialise Terraform, which downloads the necessary
plugins for it to be able to do the provisioning.

```execute
terraform init
```

The next step checks the configuration:

```execute
terraform validate
```

If that produces errors then check and correct the changes that you
made to the `tap.tf` file.
Once there are no errors you can run the final step, which will
create the cluster:

```execute
terraform apply
```

This will prompt you for the value of a variable, `nimbus_user`.

```text
var.nimbus_user
  Enter a value: 
```

You should give your VMware user ID (without any `@vmware.com` suffix).

Once you have entered that, Terraform will print out a summary of
the resources that it is going to create and issue a final prompt
before proceeding:

```text
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

As it says, type `yes` to carry on.
Anything else, even `y`, will cause the command to terminate.

You will then see a series of lines of output like the following:

```
pacific_nimbus_namespace.ns: Creating...
pacific_nimbus_namespace.ns: Still creating... [10s elapsed]
pacific_nimbus_namespace.ns: Still creating... [20s elapsed]

  ... some time later ...

pacific_nimbus_namespace.ns: Still creating... [2m10s elapsed]
pacific_nimbus_namespace.ns: Still creating... [2m20s elapsed]
pacific_nimbus_namespace.ns: Creation complete after 2m22s [id=nwinton-tap]
```

As you can see, the process can take several minutes.
At the end of this first phase the "creation complete" message will
show the name of the _namespace_ that has been created on the
Nimbus instance.
In this case the name shown is `nwinton-tap`.
This name is constructed from the username that you supplied
at the prompt and another variable `nimbus_nsname` set near the
top of the `tap.tf` file.

```section:begin
title: Note on namespaces
```

If you want to create another cluster on the same Nimbus instance
using this script, you will have to create a new namespace.
You can either do that by modifying the default value of the
`nimbus_nsname` variable in the `tap.tf`, or by overriding it when
you run the Terraform command with

```
terraform apply -var nimbus_nsname=<some-other-suffix>
```

```section:end
```

The creation process will then continue, showing more messages,
as follows:

```text
local_file.sv_kubeconfig: Creating...
local_file.sv_kubeconfig: Creation complete after 0s [id=cc3d404679238965f82c3f4d6ee153b434f6ae14]
pacific_guestcluster.gc: Creating...
pacific_guestcluster.gc: Still creating... [10s elapsed]
pacific_guestcluster.gc: Still creating... [20s elapsed]

  ... more time passes ...

pacific_guestcluster.gc: Still creating... [5m50s elapsed]
pacific_guestcluster.gc: Still creating... [6m0s elapsed]
pacific_guestcluster.gc: Still creating... [6m10s elapsed]
pacific_guestcluster.gc: Creation complete after 6m19s [id=nwinton-tap-gc]
local_file.gc_kubeconfig: Creating...
local_file.gc_kubeconfig: Creation complete after 0s [id=2e5617db333871599f9fcdca3ab3b0953339cc16]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

Again, you can see that this is likely to take a number of minutes.
At the end of the process you will see that a number of files
have been created in the `terraform` directory:

```execute
ls -l ~/terraform
```

These files are:

* `terraform.tfstate` &mdash; this records all of the information that
Terraform needs to make any subsequent modifications to your namespace
and cluster, including if you need to delete it.
* `sv.kubeconfig` &mdash; a Kubernetes configuration for the "supervisor"
cluster used to control and manage your "guest" cluster.
* `gc.kubeconfig` &mdash; the configuration giving you full admin access
to your guest cluster, where you will install TAP.

All of these files are crucial for your future use of the cluster so,
before you go any further, we will make a backup for you to download.

```terminal:execute
command: zip ~/tap-terraform.zip terraform.tfstate sv.kubeconfig gc.kubeconfig
clear: true
```

Now you should download that zip file and keep it safe!

```files:download-file
path: tap-terraform.zip
```