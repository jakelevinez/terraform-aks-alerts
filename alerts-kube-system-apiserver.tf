resource "azurerm_monitor_alert_prometheus_rule_group" "kubeapiserver" {
  name                = "kubernetes-system-apiserver"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  description         = "Kube System API Server Alerts"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubeClientCertificateExpiration"
    annotations = {
      "description" = "A client certificate used to authenticate to kubernetes apiserver is expiring in less than 7.0 days."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration"
      "summary"     = "Client certificate is about to expire."
    }
    enabled    = true
    expression = <<-EOT
              apiserver_client_certificate_expiration_seconds_count{job="kube-apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="kube-apiserver"}[5m]))) < 604800
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
    alert = "KubeClientCertificateExpiration"
    annotations = {
      "description" = "A client certificate used to authenticate to kubernetes apiserver is expiring in less than 24.0 hours."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration"
      "summary"     = "Client certificate is about to expire."
    }
    enabled    = false
    expression = <<-EOT
                apiserver_client_certificate_expiration_seconds_count{job="kube-apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="kube-apiserver"}[5m]))) < 86400
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
  rule {
    alert = "KubeAggregatedAPIErrors"
    annotations = {
      "description" = "Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has reported errors. It has appeared unavailable {{ $value | humanize }} times averaged over the past 10m."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeaggregatedapierrors"
      "summary"     = "Kubernetes aggregated API has reported errors."
    }
    enabled    = false
    expression = <<-EOT
                sum by(name, namespace, cluster)(increase(aggregator_unavailable_apiservice_total{job="kube-apiserver"}[10m])) > 4
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
    alert = "KubeAggregatedAPIDown"
    annotations = {
      "description" = "Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has been only {{ $value | humanize }}% available over the last 10m."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeaggregatedapidown"
      "summary"     = "Kubernetes aggregated API is down."
    }
    enabled    = false
    expression = <<-EOT
                (1 - max by(name, namespace, cluster)(avg_over_time(aggregator_unavailable_apiservice{job="kube-apiserver"}[10m]))) * 100 < 85
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
    alert = "KubeAPITerminatedRequests"
    annotations = {
      "description" = "The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapiterminatedrequests"
      "summary"     = "The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests."
    }
    enabled    = false
    expression = <<-EOT
                sum(rate(apiserver_request_terminations_total{job="kube-apiserver"}[10m]))  / (  sum(rate(apiserver_request_total{job="kube-apiserver"}[10m])) + sum(rate(apiserver_request_terminations_total{job="kube-apiserver"}[10m])) ) > 0.20
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
}
