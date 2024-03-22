resource "azurerm_monitor_alert_prometheus_rule_group" "reccomendedPodAlerts" {
  name                = "KubernetesAlert-RecommendedMetricAlertsaccu-sandbox-aks-Pod-level"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  description         = "Kubernetes Alert RuleGroup-RecommendedMetricAlerts - 0.1"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubePodCrashLooping"
    annotations = {
      "description" = "{{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) in {{ $labels.cluster}} is restarting {{ printf \"%.2f\" $value }} / second. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubePodCrashLooping.md)."
    }
    enabled    = true
    expression = "max_over_time(kube_pod_container_status_waiting_reason{reason=\"CrashLoopBackOff\", job=\"kube-state-metrics\"}[5m]) >= 1"
    for        = "PT15M"
    severity   = 4
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
    alert = "Job did not complete in time"
    annotations = {
      "description" = "Number of stale jobs older than six hours is greater than 0"
    }
    enabled    = true
    expression = "sum by(namespace,cluster)(kube_job_spec_completions{job=\"kube-state-metrics\"}) - sum by(namespace,cluster)(kube_job_status_succeeded{job=\"kube-state-metrics\"})  > 0 "
    for        = "PT360M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }
  rule {
    alert = "Pod container restarted more than 10 times in the last 1 hour"
    annotations = {
      "description" = "Pod container restarted more than 10 times in the last 1 hour"
    }
    enabled    = true
    expression = "sum by (namespace, controller, container, cluster)(increase(kube_pod_container_status_restarts_total{job=\"kube-state-metrics\"}[1h])* on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, \"controller\", \"$1\", \"owner_name\", \"(.*)\")) > 10"
    for        = "PT15M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "Ready state of pods is less than 80%. "
    annotations = {
      "description" = "Ready state of pods is less than 80%."
    }
    enabled    = true
    expression = "sum by (cluster,namespace,deployment)(kube_deployment_status_replicas_ready) / sum by (cluster,namespace,deployment)(kube_deployment_spec_replicas) <.8 or sum by (cluster,namespace,deployment)(kube_daemonset_status_number_ready) / sum by (cluster,namespace,deployment)(kube_daemonset_status_desired_number_scheduled) <.8 "
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }
  rule {
    alert = "Number of pods in failed state are greater than 0."
    annotations = {
      "description" = "Number of pods in failed state are greater than 0"
    }
    enabled    = true
    expression = "sum by (cluster, namespace, controller) (kube_pod_status_phase{phase=\"failed\"} * on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, \"controller\", \"$1\", \"owner_name\", \"(.*)\"))  > 0"
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }
  rule {
    alert = "KubePodNotReadyByController"
    annotations = {
      "description" = "{{ $labels.namespace }}/{{ $labels.pod }} in {{ $labels.cluster}} by controller is not ready. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubePodNotReady.md)."
    }
    enabled    = true
    expression = "sum by (namespace, controller, cluster) (max by(namespace, pod, cluster) (kube_pod_status_phase{job=\"kube-state-metrics\", phase=~\"Pending|Unknown\"}  ) * on(namespace, pod, cluster) group_left(controller)label_replace(kube_pod_owner,\"controller\",\"$1\",\"owner_name\",\"(.*)\")) > 0"
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
    alert = "KubeJobNotCompleted"
    annotations = {
      "description" = "Job {{ $labels.namespace }}/{{ $labels.job_name }} in {{ $labels.cluster}} is taking more than 12 hours to complete. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeJobCompletion.md)."
    }
    enabled    = true
    expression = "time() - max by(namespace, job_name, cluster) (kube_job_status_start_time{job=\"kube-state-metrics\"}  and kube_job_status_active{job=\"kube-state-metrics\"} > 0) > 43200"
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
    alert = "KubeJobFailed"
    annotations = {
      "description" = "Job {{ $labels.namespace }}/{{ $labels.job_name }} in {{ $labels.cluster}} failed to complete. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeJobFailed.md)."
    }
    enabled    = true
    expression = "kube_job_failed{job=\"kube-state-metrics\"}  > 0"
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
    alert = "Average CPU usage per container is greater than 95%"
    annotations = {
      "description" = "Average CPU usage per container is greater than 95%"
    }
    enabled    = true
    expression = "sum (rate(container_cpu_usage_seconds_total{image!=\"\", container!=\"POD\"}[5m])) by (pod,cluster,container,namespace) / sum(container_spec_cpu_quota{image!=\"\", container!=\"POD\"}/container_spec_cpu_period{image!=\"\", container!=\"POD\"}) by (pod,cluster,container,namespace) > .95"
    for        = "PT5M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }
  }
  rule {
    alert = "Average Memory usage per container is greater than 95%."
    annotations = {
      "description" = "Average Memory usage per container is greater than 95%"
    }
    enabled    = true
    expression = "avg by (namespace, controller, container, cluster)(((container_memory_working_set_bytes{container!=\"\", image!=\"\", container!=\"POD\"} / on(namespace,cluster,pod,container) group_left kube_pod_container_resource_limits{resource=\"memory\", node!=\"\"})*on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, \"controller\", \"$1\", \"owner_name\", \"(.*)\")) > .95)"
    for        = "PT10M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

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
      "description" = "Kubelet Pod startup latency is too high. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/kubernetes/KubeletPodStartUpLatencyHigh.md)"
    }
    enabled    = true
    expression = "histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job=\"kubelet\"}[5m])) by (cluster, instance, le)) * on(cluster, instance) group_left(node) kubelet_node_name{job=\"kubelet\"} > 60"
    for        = "PT10M"
    labels = {
      "severity" = "warning"
    }
    severity = 4

    action {
      action_group_id = var.action_group_id
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }
  }
  rule {
    alert = "Average PV usage is greater than 80%"
    annotations = {
      "description" = "Average PV usage on pod {{ $labels.pod }} in container {{ $labels.container }}  is greater than 80%"
    }
    enabled    = true
    expression = "avg by (namespace, controller, container, cluster)(((kubelet_volume_stats_used_bytes{job=\"kubelet\"} / on(namespace,cluster,pod,container) group_left kubelet_volume_stats_capacity_bytes{job=\"kubelet\"}) * on(namespace, pod, cluster) group_left(controller) label_replace(kube_pod_owner, \"controller\", \"$1\", \"owner_name\", \"(.*)\"))) > .8"
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
