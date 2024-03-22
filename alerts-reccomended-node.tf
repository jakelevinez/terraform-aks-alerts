resource "azurerm_monitor_alert_prometheus_rule_group" "reccomendedNodeAlerts" {
  name                = "KubernetesAlert-RecommendedMetricAlertsaccu-sandbox-aks-Node-level"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  description         = "Kubernetes Alert RuleGroup-RecommendedMetricAlerts - 0.1"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubeNodeUnreachable"
    annotations = {
      "description" = "{{ $labels.node }} in {{ $labels.cluster}} is unreachable and some workloads may be rescheduled. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeNodeUnreachable.md)."
    }
    enabled    = true
    expression = "(kube_node_spec_taint{job=\"kube-state-metrics\",key=\"node.kubernetes.io/unreachable\",effect=\"NoSchedule\"} unless ignoring(key,value) kube_node_spec_taint{job=\"kube-state-metrics\",key=~\"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn\"}) == 1"
    for        = "PT15M"
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
    alert = "KubeNodeNotReady"
    annotations = {
      "description" = "{{ $labels.node }} in {{ $labels.cluster}} has been unready for more than 15 minutes. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeNodeNotReady.md)."
    }
    enabled    = true
    expression = "kube_node_status_condition{job=\"kube-state-metrics\",condition=\"Ready\",status=\"true\"} == 0"
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
    alert = "KubeNodeReadinessFlapping"
    annotations = {
      "description" = "The readiness status of node {{ $labels.node }} in {{ $labels.cluster}} has changed more than 2 times in the last 15 minutes. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeNodeReadinessFlapping.md)."
    }
    enabled    = true
    expression = "sum(changes(kube_node_status_condition{status=\"true\",condition=\"Ready\"}[15m])) by (cluster, node) > 2"
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
}
