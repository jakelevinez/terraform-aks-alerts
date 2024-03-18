resource "azurerm_monitor_alert_prometheus_rule_group" "kubestorage" {
  name                = "kubernetes-storage"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes = [

  ]

  rule {
    alert = "KubePersistentVolumeFillingUp"
    annotations = {
      "description" = "The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is only {{ $value | humanizePercentage }} free."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumefillingup"
      "summary"     = "PersistentVolume is filling up."
    }
    enabled    = true
    expression = <<-EOT
               (
                 kubelet_volume_stats_available_bytes{job="kubelet"}
                   /
                 kubelet_volume_stats_capacity_bytes{job="kubelet"}
               ) < 0.03
               and
               kubelet_volume_stats_used_bytes{job="kubelet"} > 0
               unless on(namespace, persistentvolumeclaim)
               kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
               unless on(namespace, persistentvolumeclaim)
               kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
            EOT
    for        = "PT1M"
    labels = {
      "severity" = "critical"
    }
    severity = 3

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "KubePersistentVolumeFillingUp"
    annotations = {
      "description" = "Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumefillingup"
      "summary"     = "PersistentVolume is filling up."
    }
    enabled    = true
    expression = <<-EOT
                (
                  kubelet_volume_stats_available_bytes{job="kubelet"}
                    /
                  kubelet_volume_stats_capacity_bytes{job="kubelet"}
                ) < 0.15
                and
                kubelet_volume_stats_used_bytes{job="kubelet"} > 0
                and
                predict_linear(kubelet_volume_stats_available_bytes{job="kubelet"}[6h], 4 * 24 * 3600) < 0
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
            EOT 
    for        = "PT1H"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "KubePersistentVolumeInodesFillingUp"
    annotations = {
      "description" = "The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} only has {{ $value | humanizePercentage }} free inodes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeinodesfillingup"
      "summary"     = "PersistentVolumeInodes are filling up."
    }
    enabled    = true
    expression = <<-EOT
                (
                  kubelet_volume_stats_inodes_free{job="kubelet"}
                    /
                  kubelet_volume_stats_inodes{job="kubelet"}
                ) < 0.03
                and
                kubelet_volume_stats_inodes_used{job="kubelet"} > 0
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
            EOT 
    for        = "PT1M"
    labels = {
      "severity" = "critical"
    }
    severity = 3

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "KubePersistentVolumeInodesFillingUp"
    annotations = {
      "description" = "Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to run out of inodes within four days. Currently {{ $value | humanizePercentage }} of its inodes are free."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeinodesfillingup"
      "summary"     = "PersistentVolumeInodes are filling up."
    }
    enabled    = true
    expression = <<-EOT
                (
                  kubelet_volume_stats_inodes_free{job="kubelet"}
                    /
                  kubelet_volume_stats_inodes{job="kubelet"}
                ) < 0.15
                and
                kubelet_volume_stats_inodes_used{job="kubelet"} > 0
                and
                predict_linear(kubelet_volume_stats_inodes_free{job="kubelet"}[6h], 4 * 24 * 3600) < 0
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
                unless on(namespace, persistentvolumeclaim)
                kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
            EOT 
    for        = "PT1H"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "KubePersistentVolumeErrors"
    annotations = {
      "description" = "The persistent volume {{ $labels.persistentvolume }} has status {{ $labels.phase }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeerrors"
      "summary"     = "PersistentVolume is having issues with provisioning."
    }
    enabled    = true
    expression = <<-EOT
                kube_persistentvolume_status_phase{phase=~"Failed|Pending",job="kube-state-metrics"} > 0
            EOT 
    for        = "PT5M"
    labels = {
      "severity" = "critical"
    }
    severity = 3

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
}
