variable "nimbus_user" {
  # This will be prompted for
}

variable "nimbus_nsname" {
  # You can change this if you wish
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

resource "pacific_nimbus_namespace" "ns" {
  user          = var.nimbus_user
  name          = var.nimbus_nsname

  # Pick one of the following for the Nimbus instance vCenter
  # sc2-01-vc16 (may have a short lease on environments)
  # sc2-01-vc17
  # wdc-08-vc04 (known issues at 28/04/22)
  # wdc-08-vc05 (known issues at 28/04/22)
  # wdc-08-vc07
  # wdc-08-vc08
  # Check slack channel #calatrava-notice for current known issues
  nimbus             = "REPLACE-ME"
  # Leave this as is
  nimbus_config_file = "/mts/git/nimbus-configs/config/staging/wcp.json"
}

// save kubeconfig
resource "local_sensitive_file" "sv_kubeconfig" {
  content = pacific_nimbus_namespace.ns.kubeconfig
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
  topology_controlplane_count        = 1      # 3 nodes are recommended for prod and stage work load for high availability and 1 for test workload
  topology_controlplane_storageclass = pacific_nimbus_namespace.ns.default_storageclass
  topology_nodepool {
    name = "pool-0"
    count = 6
    storageclass = pacific_nimbus_namespace.ns.default_storageclass
    class = "best-effort-small"
    volume {
      name             = "containerd"
      mountpath         = "/var/lib/containerd"
      capacity_storage = "32Gi"
    }
    volume {
      name             = "log"
      mountpath         = "/var/log/containers"
      capacity_storage = "32Gi"
    }
  }
  storage_defaultclass               = pacific_nimbus_namespace.ns.default_storageclass
}

// save kubeconfig
resource "local_sensitive_file" "gc_kubeconfig" {
  content = pacific_guestcluster.gc.kubeconfig
  filename          = "${path.module}/gc.kubeconfig"
  file_permission   = "0644"
}
