variable "nimbus_user" {

}

variable "nimbus_nsname" {
  default = "tap"
}

terraform {
  required_providers {
    pacific = {
      # The legacy locally installed pacific provider
      # source = "eng.vmware.com/calatrava/pacific"

      source = "cdickmann-terraform-registry.object1-wdc.calatrava.vmware.com/terraform-registry/pacific"
    }
  }
}

# Keep the nimbus server/config/ip values, they are fine for you to use
resource "pacific_nimbus_namespace" "ns" {
  user          = var.nimbus_user
  name          = var.nimbus_nsname

  # Pick one of sc2-01-vc16, sc2-01-vc17, wdc-08-vc04, wdc-08-vc05, wdc-08-vc07, wdc-08-vc08
  # Check slack channel #calatrava-notice for known issues
  nimbus             = "REPLACE-ME"
  nimbus_config_file = "/mts/git/nimbus-configs/config/staging/wcp.json"
}

// save kubeconfig
resource "local_file" "sv_kubeconfig" {
  sensitive_content = pacific_nimbus_namespace.ns.kubeconfig
  filename          = "${path.module}/sv.kubeconfig"
  file_permission   = "0644"
}

resource "pacific_guestcluster" "gc" {
  cluster_name     = "gc"
  namespace        = pacific_nimbus_namespace.ns.namespace
  input_kubeconfig = pacific_nimbus_namespace.ns.kubeconfig
  # versions older than v1.19 are deprecated
  version                            = "v1.21.2"
  network_servicedomain              = "cluster.local"
  topology_controlplane_class        = "best-effort-medium"
  topology_workers_class             = "best-effort-small"
  topology_workers_count             = 6
  topology_controlplane_count        = 1      #3 nodes are recommended for prod and stage work load for high availability and 1 for test workload
  topology_controlplane_storageclass = pacific_nimbus_namespace.ns.default_storageclass
  topology_workers_storageclass      = pacific_nimbus_namespace.ns.default_storageclass
  storage_defaultclass               = pacific_nimbus_namespace.ns.default_storageclass

  # Container volume
  topology_workers_volumes {
    name             = "containerd"
    mountpath         = "/var/lib/containerd"
    capacity_storage = "32Gi"
  }

  # Log volume
  topology_workers_volumes {
    name             = "log"
    mountpath         = "/var/log/containers"
    capacity_storage = "32Gi"
  }

}

// save kubeconfig
resource "local_file" "gc_kubeconfig" {
  sensitive_content = pacific_guestcluster.gc.kubeconfig
  filename          = "${path.module}/gc.kubeconfig"
  file_permission   = "0644"
}
