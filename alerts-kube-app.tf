resource "azurerm_monitor_alert_prometheus_rule_group" "kubeapps" {
  name                = "kubernetes-apps"
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = azurerm_kubernetes_cluster.cluster.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = []

  rule {
    alert = "KubePodCrashLooping"
    annotations = {
      "description" = "Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is in waiting state (reason: \"CrashLoopBackOff\")."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodcrashlooping"
      "summary"     = "Pod is crash looping."
    }
    enabled    = true
    expression = <<-EOT
                max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics"}[5m]) >= 1
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
    alert = "KubePodNotReady"
    annotations = {
      "description" = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodnotready"
      "summary"     = "Pod has been in a non-ready state for more than 15 minutes."
    }
    enabled    = true
    expression = <<-EOT
                sum by (namespace, pod, cluster) (
                  max by(namespace, pod, cluster) (
                    kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown|Failed"}
                  ) * on(namespace, pod, cluster) group_left(owner_kind) topk by(namespace, pod, cluster) (
                    1, max by(namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!="Job"})
                  )
                ) > 0
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
    alert = "KubeDeploymentGenerationMismatch"
    annotations = {
      "description" = "Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment }} does not match, this indicates that the Deployment has failed but has not been rolled back."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentgenerationmismatch"
      "summary"     = "Deployment generation mismatch due to possible roll-back"
    }
    enabled    = true
    expression = <<-EOT
                kube_deployment_status_observed_generation{job="kube-state-metrics"}
                  !=
                kube_deployment_metadata_generation{job="kube-state-metrics"}
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
    alert = "KubeDeploymentReplicasMismatch"
    annotations = {
      "description" = "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not matched the expected number of replicas for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentreplicasmismatch"
      "summary"     = "Deployment has not matched the expected number of replicas."
    }
    enabled    = true
    expression = <<-EOT
                (
                  kube_deployment_spec_replicas{job="kube-state-metrics"}
                    >
                  kube_deployment_status_replicas_available{job="kube-state-metrics"}
                ) and (
                  changes(kube_deployment_status_replicas_updated{job="kube-state-metrics"}[10m])
                    ==
                  0
                )
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
    alert = "KubeDeploymentRolloutStuck"
    annotations = {
      "description" = "Rollout of deployment {{ $labels.namespace }}/{{ $labels.deployment }} is not progressing for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentrolloutstuck"
      "summary"     = "Deployment rollout is not progressing."
    }
    enabled    = true
    expression = <<-EOT
                kube_deployment_status_condition{condition="Progressing", status="false",job="kube-state-metrics"}
                != 0
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
    alert = "KubeStatefulSetReplicasMismatch"
    annotations = {
      "description" = "StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has not matched the expected number of replicas for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetreplicasmismatch"
      "summary"     = "StatefulSet has not matched the expected number of replicas."
    }
    enabled    = true
    expression = <<-EOT
                (
                  kube_statefulset_status_replicas_ready{job="kube-state-metrics"}
                    !=
                  kube_statefulset_status_replicas{job="kube-state-metrics"}
                ) and (
                  changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[10m])
                    ==
                  0
                )
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
    alert = "KubeStatefulSetGenerationMismatch"
    annotations = {
      "description" = "StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetgenerationmismatch"
      "summary"     = "StatefulSet generation mismatch due to possible roll-back"
    }
    enabled    = true
    expression = <<-EOT
                kube_statefulset_status_observed_generation{job="kube-state-metrics"}
                  !=
                kube_statefulset_metadata_generation{job="kube-state-metrics"}
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
    alert = "KubeStatefulSetUpdateNotRolledOut"
    annotations = {
      "description" = "StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update has not been rolled out."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetupdatenotrolledout"
      "summary"     = "StatefulSet update has not been rolled out."
    }
    enabled    = true
    expression = <<-EOT
                (
                  max without (revision) (
                    kube_statefulset_status_current_revision{job="kube-state-metrics"}
                      unless
                    kube_statefulset_status_update_revision{job="kube-state-metrics"}
                  )
                    *
                  (
                    kube_statefulset_replicas{job="kube-state-metrics"}
                      !=
                    kube_statefulset_status_replicas_updated{job="kube-state-metrics"}
                  )
                )  and (
                  changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[5m])
                    ==
                  0
                )
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
    alert = "KubeDaemonSetRolloutStuck"
    annotations = {
      "description" = "DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} has not finished or progressed for at least 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetrolloutstuck"
      "summary"     = "DaemonSet rollout is stuck."
    }
    enabled    = true
    expression = <<-EOT
                (
                  (
                    kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"}
                     !=
                    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
                  ) or (
                    kube_daemonset_status_number_misscheduled{job="kube-state-metrics"}
                     !=
                    0
                  ) or (
                    kube_daemonset_status_updated_number_scheduled{job="kube-state-metrics"}
                     !=
                    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
                  ) or (
                    kube_daemonset_status_number_available{job="kube-state-metrics"}
                     !=
                    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
                  )
                ) and (
                  changes(kube_daemonset_status_updated_number_scheduled{job="kube-state-metrics"}[5m])
                    ==
                  0
                )
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
    alert = "KubeContainerWaiting"
    annotations = {
      "description" = "pod/{{ $labels.pod }} in namespace {{ $labels.namespace }} on container {{ $labels.container}} has been in waiting state for longer than 1 hour."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecontainerwaiting"
      "summary"     = "Pod container waiting longer than 1 hour"
    }
    enabled    = true
    expression = <<-EOT
                sum by (namespace, pod, container, cluster) (kube_pod_container_status_waiting_reason{job="kube-state-metrics"}) > 0
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
    alert = "KubeDaemonSetNotScheduled"
    annotations = {
      "description" = "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetnotscheduled"
      "summary"     = "DaemonSet pods are not scheduled."
    }
    enabled    = true
    expression = <<-EOT
                kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
                  -
                kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"} > 0
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
    alert = "KubeDaemonSetMisScheduled"
    annotations = {
      "description" = "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetmisscheduled"
      "summary"     = "DaemonSet pods are misscheduled."
    }
    enabled    = true
    expression = <<-EOT
                kube_daemonset_status_number_misscheduled{job="kube-state-metrics"} > 0
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
    alert = "KubeJobNotCompleted"
    annotations = {
      "description" = "Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more than {{ \"43200\" | humanizeDuration }} to complete."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobnotcompleted"
      "summary"     = "Job did not complete in time"
    }
    enabled    = true
    expression = <<-EOT
                time() - max by(namespace, job_name, cluster) (kube_job_status_start_time{job="kube-state-metrics"}
                  and
                kube_job_status_active{job="kube-state-metrics"} > 0) > 43200
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
    alert = "KubeJobFailed"
    annotations = {
      "description" = "Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete. Removing failed job after investigation should clear this alert."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobfailed"
      "summary"     = "Job failed to complete."
    }
    enabled    = true
    expression = <<-EOT
                kube_job_failed{job="kube-state-metrics"}  > 0
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
    alert = "KubeHpaReplicasMismatch"
    annotations = {
      "description" = "HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has not matched the desired number of replicas for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpareplicasmismatch"
      "summary"     = "HPA has not matched desired number of replicas."
    }
    enabled    = true
    expression = <<-EOT
                (kube_horizontalpodautoscaler_status_desired_replicas{job="kube-state-metrics"}
                  !=
                kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"})
                  and
                (kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}
                  >
                kube_horizontalpodautoscaler_spec_min_replicas{job="kube-state-metrics"})
                  and
                (kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}
                  <
                kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"})
                  and
                changes(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}[15m]) == 0
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
    alert = "KubeHpaMaxedOut"
    annotations = {
      "description" = "HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has been running at max replicas for longer than 15 minutes."
      "runbook_url" = "https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpamaxedout"
      "summary"     = "HPA is running at max replicas"
    }
    enabled    = true
    expression = <<-EOT
                kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}
                  ==
                kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"}
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
