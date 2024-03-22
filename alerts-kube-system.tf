resource "azurerm_monitor_alert_prometheus_rule_group" "kubesystem" {
  name                = "kubernetes-system"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubeVersionMismatch"
    annotations = {
      "description" = "There are {{ $value }} different semantic versions of Kubernetes components running."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeversionmismatch"
      "summary"     = "Different semantic versions of Kubernetes components running."
    }
    enabled    = true
    expression = <<-EOT
                count by (cluster) (count by (git_version, cluster) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"git_version","$1","git_version","(v[0-9]*.[0-9]*).*"))) > 1
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
    alert = "KubeClientErrors"
    annotations = {
      "description" = "Kubernetes API server client '{{ $labels.job }}/{{ $labels.instance }}' is experiencing {{ $value | humanizePercentage }} errors.'"
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclienterrors"
      "summary"     = "Kubernetes API server client is experiencing errors."
    }
    enabled    = true
    expression = <<-EOT
                (sum(rate(rest_client_requests_total{job="kube-apiserver",code=~"5.."}[5m])) by (cluster, instance, job, namespace)
                  /
                sum(rate(rest_client_requests_total{job="kube-apiserver"}[5m])) by (cluster, instance, job, namespace))
                > 0.01
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
}
