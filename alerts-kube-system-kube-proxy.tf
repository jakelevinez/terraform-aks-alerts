resource "azurerm_monitor_alert_prometheus_rule_group" "kubesystemkubeproxy" {
  name                = "kubernetes-system-kube-proxy"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubeProxyDown"
    annotations = {
      "description" = "KubeProxy has disappeared from Prometheus target discovery."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeproxydown"
      "summary"     = "Target disappeared from Prometheus target discovery."
    }
    enabled    = true
    expression = <<-EOT
                absent(up{job="kube-proxy"} == 1)
            EOT
    for        = "PT15M"
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
