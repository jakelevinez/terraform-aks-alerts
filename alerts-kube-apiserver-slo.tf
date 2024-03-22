resource "azurerm_monitor_alert_prometheus_rule_group" "kubeapiserverslo" {
  name                = "kube-apiserver-slos"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  description         = "The API server is burning too much error budget."
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes = []

  rule {
    alert = "KubeAPIErrorBudgetBurn"
    annotations = {
      "description" = "The API server is burning too much error budget."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn"
      "summary"     = "The API server is burning too much error budget."
    }
    enabled    = true
    expression = <<-EOT
              sum(apiserver_request:burnrate1h) > (14.40 * 0.01000)
              and
              sum(apiserver_request:burnrate5m) > (14.40 * 0.01000)
            EOT
    for        = "PT2M"
    labels = {
      "long"     = "1h"
      "severity" = "critical"
      "short"    = "5m"
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
    alert = "KubeAPIErrorBudgetBurn"
    annotations = {
      "description" = "The API server is burning too much error budget."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn"
      "summary"     = "The API server is burning too much error budget."
    }
    enabled    = true
    expression = <<-EOT
                sum(apiserver_request:burnrate6h) > (6.00 * 0.01000)
                and
                sum(apiserver_request:burnrate30m) > (6.00 * 0.01000)
            EOT 
    for        = "PT15M"
    labels = {
      "long"     = "6h"
      "severity" = "critical"
      "short"    = "30m"
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
    alert = "KubeAPIErrorBudgetBurn"
    annotations = {
      "description" = "The API server is burning too much error budget."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn"
      "summary"     = "The API server is burning too much error budget."
    }
    enabled    = true
    expression = <<-EOT
                sum(apiserver_request:burnrate1d) > (3.00 * 0.01000)
                and
                sum(apiserver_request:burnrate2h) > (3.00 * 0.01000)
            EOT 
    for        = "PT1H"
    labels = {
      "long"     = "1d"
      "severity" = "warning"
      "short"    = "2h"
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
    alert = "KubeAPIErrorBudgetBurn"
    annotations = {
      "description" = "The API server is burning too much error budget."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn"
      "summary"     = "The API server is burning too much error budget."
    }
    enabled    = true
    expression = <<-EOT
                sum(apiserver_request:burnrate3d) > (1.00 * 0.01000)
                and
                sum(apiserver_request:burnrate6h) > (1.00 * 0.01000)
            EOT 
    for        = "PT3H"
    labels = {
      "long"     = "3d"
      "severity" = "warning"
      "short"    = "6h"
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
