resource "azurerm_monitor_alert_prometheus_rule_group" "kubesystemkubelet" {
  name                = "kubernetes-system-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubeNodeNotReady"

    annotations = {
      "description" = "{{ $labels.node }} has been unready for more than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodenotready"
      "summary"     = "Node is not ready."
    }
    enabled    = true
    expression = <<-EOT
                kube_node_status_condition{job="kube-state-metrics",condition="Ready",status="true"} == 0
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
    alert = "KubeNodeUnreachable"
    annotations = {
      "description" = "{{ $labels.node }} is unreachable and some workloads may be rescheduled."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodeunreachable"
      "summary"     = "Node is unreachable."
    }
    enabled    = false
    expression = <<-EOT
                (kube_node_spec_taint{job="kube-state-metrics",key="node.kubernetes.io/unreachable",effect="NoSchedule"} unless ignoring(key,value) kube_node_spec_taint{job="kube-state-metrics",key=~"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn"}) == 1
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
    alert = "KubeletTooManyPods"
    annotations = {
      "description" = "Kubelet '{{ $labels.node }}' is running at {{ $value | humanizePercentage }} of its Pod capacity."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubelettoomanypods"
      "summary"     = "Kubelet is running at capacity."
    }
    enabled    = false
    expression = <<-EOT
                count by(cluster, node) (
                  (kube_pod_status_phase{job="kube-state-metrics",phase="Running"} == 1) * on(instance,pod,namespace,cluster) group_left(node) topk by(instance,pod,namespace,cluster) (1, kube_pod_info{job="kube-state-metrics"})
                )
                /
                max by(cluster, node) (
                  kube_node_status_capacity{job="kube-state-metrics",resource="pods"} != 1
                ) > 0.95
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
    alert = "KubeNodeReadinessFlapping"
    annotations = {
      "description" = "The readiness status of node {{ $labels.node }} has changed {{ $value }} times in the last 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodereadinessflapping"
      "summary"     = "Node readiness status is flapping."
    }
    enabled    = false
    expression = <<-EOT
                sum(changes(kube_node_status_condition{job="kube-state-metrics",status="true",condition="Ready"}[15m])) by (cluster, node) > 2
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
    alert = "KubeletPlegDurationHigh"
    annotations = {
      "description" = "The Kubelet Pod Lifecycle Event Generator has a 99th percentile duration of {{ $value }} seconds on node {{ $labels.node }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletplegdurationhigh"
      "summary"     = "Kubelet Pod Lifecycle Event Generator is taking too long to relist."
    }
    enabled    = false
    expression = <<-EOT
                node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile{quantile="0.99"} >= 10
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
    alert = "KubeletPodStartUpLatencyHigh"
    annotations = {
      "description" = "Kubelet Pod startup 99th percentile latency is {{ $value }} seconds on node {{ $labels.node }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletpodstartuplatencyhigh"
      "summary"     = "Kubelet Pod startup latency is too high."
    }
    enabled    = false
    expression = <<-EOT
                histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job="kubelet"}[5m])) by (cluster, instance, le)) * on(cluster, instance) group_left(node) kubelet_node_name{job="kubelet"} > 60
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
    alert = "KubeletClientCertificateExpiration"
    annotations = {
      "description" = "Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificateexpiration"
      "summary"     = "Kubelet client certificate is about to expire."
    }
    enabled    = false
    expression = <<-EOT
                kubelet_certificate_manager_client_ttl_seconds < 604800
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
    alert = "KubeletClientCertificateExpiration"
    annotations = {
      "description" = "Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificateexpiration"
      "summary"     = "Kubelet client certificate is about to expire."
    }
    enabled    = false
    expression = <<-EOT
                kubelet_certificate_manager_client_ttl_seconds < 86400
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
  rule {
    alert = "KubeletServerCertificateExpiration"
    annotations = {
      "description" = "Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificateexpiration"
      "summary"     = "Kubelet server certificate is about to expire."
    }
    enabled    = false
    expression = <<-EOT
                kubelet_certificate_manager_server_ttl_seconds < 604800
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
    alert = "KubeletServerCertificateExpiration"
    annotations = {
      "description" = "Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificateexpiration"
      "summary"     = "Kubelet server certificate is about to expire."
    }
    enabled    = false
    expression = <<-EOT
                kubelet_certificate_manager_server_ttl_seconds < 86400
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
  rule {
    alert = "KubeletClientCertificateRenewalErrors"
    annotations = {
      "description" = "Kubelet on node {{ $labels.node }} has failed to renew its client certificate ({{ $value | humanize }} errors in the last 5 minutes)."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificaterenewalerrors"
      "summary"     = "Kubelet has failed to renew its client certificate."
    }
    enabled    = false
    expression = <<-EOT
                increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0
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
    alert = "KubeletServerCertificateRenewalErrors"
    annotations = {
      "description" = "Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes)."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificaterenewalerrors"
      "summary"     = "Kubelet has failed to renew its server certificate."
    }
    enabled    = false
    expression = <<-EOT
                increase(kubelet_server_expiration_renew_errors[5m]) > 0
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
    alert = "KubeletDown"
    annotations = {
      "description" = "Kubelet has disappeared from Prometheus target discovery."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletdown"
      "summary"     = "Target disappeared from Prometheus target discovery."
    }
    enabled    = false
    expression = <<-EOT
                absent(up{job="kubelet"} == 1)
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
