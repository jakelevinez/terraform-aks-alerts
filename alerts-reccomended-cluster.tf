resource "azurerm_monitor_alert_prometheus_rule_group" "reccomendedClusterAlerts" {
  name                = "KubernetesAlert-RecommendedMetricAlertsaccu-sandbox-aks-Cluster-level"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  description         = "Kubernetes Alert RuleGroup-RecommendedMetricAlerts - 0.1"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes = [

  ]

  rule {
    alert = "KubeCPUQuotaOvercommit"
    annotations = {
      "description" = "Cluster {{ $labels.cluster}} has overcommitted CPU resource requests for Namespaces. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeCPUQuotaOvercommit.md)"
    }
    enabled    = true
    expression = "sum(min without(resource) (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\", resource=~\"(cpu|requests.cpu)\"}))  /sum(kube_node_status_allocatable{resource=\"cpu\", job=\"kube-state-metrics\"})  > 1.5"
    for        = "PT5M"
    severity   = 3
    labels = {
      "severity" = "warning"
    }
    action {
      action_group_id = var.action_group_id

    }
    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeMemoryQuotaOvercommit"
    annotations = {
      "description" = "Cluster {{ $labels.cluster}} has overcommitted memory resource requests for Namespaces. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeMemoryQuotaOvercommit.md)"
    }
    enabled    = true
    expression = "sum(min without(resource) (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\", resource=~\"(memory|requests.memory)\"}))  /sum(kube_node_status_allocatable{resource=\"memory\", job=\"kube-state-metrics\"})  > 1.5"
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeVersionMismatch"
    annotations = {
      "description" = "There are {{ $value }} different versions of Kubernetes components running in {{ $labels.cluster}}. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeVersionMismatch.md)"
    }
    enabled    = true
    expression = "count by (cluster) (count by (git_version, cluster) (label_replace(kubernetes_build_info{job!~\"kube-dns|coredns\"},\"git_version\",\"$1\",\"git_version\",\"(v[0-9]*.[0-9]*).*\"))) > 1"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "Number of OOM killed containers is greater than 0"
    annotations = {
      "description" = "Number of OOM killed containers is greater than 0"
    }
    enabled    = true
    expression = "sum by (cluster,container,controller,namespace)(kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\"} * on(cluster,namespace,pod) group_left(controller) label_replace(kube_pod_owner, \"controller\", \"$1\", \"owner_name\", \"(.*)\")) > 0"
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeClientErrors"
    annotations = {
      "description" = "Kubernetes API server client '{{ $labels.job }}/{{ $labels.instance }}' is experiencing {{ $value | humanizePercentage }} errors. Please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeClientErrors.md)"
    }
    enabled    = true
    expression = "(sum(rate(rest_client_requests_total{code=~\"5..\"}[5m])) by (cluster, instance, job, namespace)  / sum(rate(rest_client_requests_total[5m])) by (cluster, instance, job, namespace)) > 0.01"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubePersistentVolumeFillingUp"
    annotations = {
      "description" = "Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubePersistentVolumeFillingUp.md)"
    }
    enabled    = true
    expression = "kubelet_volume_stats_available_bytes{job=\"kubelet\"}/kubelet_volume_stats_capacity_bytes{job=\"kubelet\"} < 0.15 and kubelet_volume_stats_used_bytes{job=\"kubelet\"} > 0 and predict_linear(kubelet_volume_stats_available_bytes{job=\"kubelet\"}[6h], 4 * 24 * 3600) < 0 unless on(namespace, persistentvolumeclaim) kube_persistentvolumeclaim_access_mode{ access_mode=\"ReadOnlyMany\"} == 1 unless on(namespace, persistentvolumeclaim) kube_persistentvolumeclaim_labels{label_excluded_from_alerts=\"true\"} == 1"
    for        = "PT60M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }

  rule {
    alert = "KubePersistentVolumeInodesFillingUp"
    annotations = {
      "description" = "The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} only has {{ $value | humanizePercentage }} free inodes."
    }
    enabled    = true
    expression = "kubelet_volume_stats_inodes_free{job=\"kubelet\"} / kubelet_volume_stats_inodes{job=\"kubelet\"} < 0.03"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubePersistentVolumeErrors"
    annotations = {
      "description" = "The persistent volume {{ $labels.persistentvolume }} has status {{ $labels.phase }}. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubePersistentVolumeErrors.md)"
    }
    enabled    = true
    expression = "kube_persistentvolume_status_phase{phase=~\"Failed|Pending\",job=\"kube-state-metrics\"} > 0"
    for        = "PT05M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeContainerWaiting"
    annotations = {
      "description" = "pod/{{ $labels.pod }} in namespace {{ $labels.namespace }} on container {{ $labels.container}} has been in waiting state for longer than 1 hour."
    }
    enabled    = true
    expression = "sum by (namespace, pod, container, cluster) (kube_pod_container_status_waiting_reason{job=\"kube-state-metrics\"}) > 0"
    for        = "PT60M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeDaemonSetNotScheduled"
    annotations = {
      "description" = "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled."
    }
    enabled    = true
    expression = "kube_daemonset_status_desired_number_scheduled{job=\"kube-state-metrics\"} - kube_daemonset_status_current_number_scheduled{job=\"kube-state-metrics\"} > 0"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeDaemonSetMisScheduled"
    annotations = {
      "description" = "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run."
    }
    enabled    = true
    expression = "kube_daemonset_status_number_misscheduled{job=\"kube-state-metrics\"} > 0"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeletClientCertificateExpiration"
    annotations = {
      "description" = "Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
    }
    enabled    = true
    expression = "kubelet_certificate_manager_client_ttl_seconds < 7 * 24 * 3600"
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }

  rule {
    alert = "KubeletServerCertificateExpiration"
    annotations = {
      "description" = "Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
    }
    enabled    = true
    expression = "kubelet_certificate_manager_server_ttl_seconds < 7 * 24 * 3600"
    for        = "PT10M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeletClientCertificateRenewalErrors"
    annotations = {
      "description" = "Kubelet on node {{ $labels.node }} has failed to renew its client certificate ({{ $value | humanize }} errors in the last 5 minutes)."
    }
    enabled    = true
    expression = "increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeletServerCertificateRenewalErrors"
    annotations = {
      "description" = "Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes)."
    }
    enabled    = true
    expression = "increase(kubelet_server_expiration_renew_errors[5m]) > 0"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeQuotaAlmostFull"
    annotations = {
      "description" = "{{ $value | humanizePercentage }} usage of {{ $labels.resource }} in namespace {{ $labels.namespace }} in {{ $labels.cluster}}. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeQuotaAlmostFull.md)."
    }
    enabled    = true
    expression = "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"}  / ignoring(instance, job, type)(kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0)  > 0.9 < 1"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 3

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeQuotaFullyUsed"
    annotations = {
      "description" = "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota."
    }
    enabled    = true
    expression = "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"} / ignoring(instance, job, type) (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0) == 1"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }

  rule {
    alert = "KubeQuotaExceeded"
    annotations = {
      "description" = "Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes)."
    }
    enabled    = true
    expression = "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"}  / ignoring(instance, job, type)  (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0) > 1"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = "/subscriptions/602d3ad2-0ba2-4972-9d88-f87ca5b67ab2/resourceGroups/rg-pd-alerts/providers/Microsoft.Insights/actionGroups/aks-nprod-action-group"
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
}
