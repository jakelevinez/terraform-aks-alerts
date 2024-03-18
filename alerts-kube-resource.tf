resource "azurerm_monitor_alert_prometheus_rule_group" "kuberesources" {
  name                = "kubernetes-resources"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes = [

  ]

  rule {
    alert = "KubeCPUOvercommit"
    annotations = {
      "description" = "Cluster has overcommitted CPU resource requests for Pods by {{ $value }} CPU shares and cannot tolerate node failure."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuovercommit"
      "summary"     = "Cluster has overcommitted CPU resource requests."
    }
    enabled    = true
    expression = <<-EOT
               sum(namespace_cpu:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})) > 0
               and
               (sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})) > 0
            EOT
    for        = "PT10M"
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
    alert = "KubeMemoryOvercommit"
    annotations = {
      "description" = "Cluster has overcommitted memory resource requests for Pods by {{ $value | humanize }} bytes and cannot tolerate node failure."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememoryovercommit"
      "summary"     = "Cluster has overcommitted memory resource requests."
    }
    enabled    = true
    expression = <<-EOT
                sum(namespace_memory:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})) > 0
                and
                (sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})) > 0
            EOT 
    for        = "PT10M"
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
    alert = "KubeCPUQuotaOvercommit"
    annotations = {
      "description" = "Cluster has overcommitted CPU resource requests for Namespaces."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuquotaovercommit"
      "summary"     = "Cluster has overcommitted CPU resource requests."
    }
    enabled    = true
    expression = <<-EOT
                sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(cpu|requests.cpu)"}))
                  /
                sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})
                  > 1.5
            EOT 
    for        = "PT5M"
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
    alert = "KubeMemoryQuotaOvercommit"
    annotations = {
      "description" = "Cluster has overcommitted memory resource requests for Namespaces."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememoryquotaovercommit"
      "summary"     = "Cluster has overcommitted memory resource requests."
    }
    enabled    = true
    expression = <<-EOT
                sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(memory|requests.memory)"}))
                  /
                sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})
                  > 1.5
            EOT 
    for        = "PT5M"
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
    alert = "KubeQuotaAlmostFull"
    annotations = {
      "description" = "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaalmostfull"
      "summary"     = "Namespace quota is going to be full."
    }
    enabled    = true
    expression = <<-EOT
                kube_resourcequota{job="kube-state-metrics", type="used"}
                  / ignoring(instance, job, type)
                (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)
                  > 0.9 < 1
            EOT 
    for        = "PT15M"
    labels = {
      "severity" = "info"
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
    alert = "KubeQuotaFullyUsed"
    annotations = {
      "description" = "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotafullyused"
      "summary"     = "Namespace quota is fully used."
    }
    enabled    = true
    expression = <<-EOT
                kube_resourcequota{job="kube-state-metrics", type="used"}
                  / ignoring(instance, job, type)
                (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)
                  == 1
            EOT 
    for        = "PT15M"
    labels = {
      "severity" = "info"
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
    alert = "KubeQuotaExceeded"
    annotations = {
      "description" = "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaexceeded"
      "summary"     = "Namespace quota has exceeded the limits."
    }
    enabled    = true
    expression = <<-EOT
                kube_resourcequota{job="kube-state-metrics", type="used"}
                  / ignoring(instance, job, type)
                (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)
                  > 1
            EOT 
    for        = "PT15M"
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
    alert = "CPUThrottlingHigh"
    annotations = {
      "description" = "{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-cputhrottlinghigh"
      "summary"     = "Processes experience elevated CPU throttling."
    }
    enabled    = true
    expression = <<-EOT
                sum(increase(container_cpu_cfs_throttled_periods_total{container!="", }[5m])) by (container, pod, namespace)
                  /
                sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace)
                  > ( 25 / 100 )
            EOT 
    for        = "PT15M"
    labels = {
      "severity" = "info"
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
