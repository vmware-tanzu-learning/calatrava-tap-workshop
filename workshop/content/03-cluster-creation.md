Before you can install Tanzu Application Platform you first need to
create a Kubernetes cluster in Calatrava.
The mechanism provided to do this is by using
[Terraform](https://terraform.io).
Fortunately, you don't need to know anything about Terraform in order
to be able to do this, as we've provided everything that you will
need here.

So, start off by going to the `terraform` sub-directory.

#### Click to execute

```execute
cd ~/terraform
ls -l
```

In that directory you will see a single file, `tap.tf`.
This is the Terraform script that you will use.
If you're comfortable at the Linux command line you can use
`vim` or `nano` to examine it, but the next few steps will walk
you through possible modifications you might want to make
using the built-in workshop editor.

#### Click to open the file

```editor:open-file
file: ~/terraform/tap.tf
```

Calatrava uses the
[Nimbus](https://confluence.eng.vmware.com/display/DevToolsDocKB/Nimbus+User+Guide)
internal cloud infrastructure.
In particular, it uses vSphere 7.0 with Tanzu (TKGs) to provision
clusters.
So you need to choose a Nimbus instance (vCenter) on which to create
yor cluster.
That is set at the line beginning with `nimbus = ...`

#### Go to the line

```editor:select-matching-text
file: ~/terraform/tap.tf
text: "nimbus\s+=\s+\"(.*)\""
isRegex: true
group: 1
```


