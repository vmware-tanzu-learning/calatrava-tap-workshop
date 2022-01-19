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

And wait ...