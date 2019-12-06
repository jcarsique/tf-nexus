# kubernetes versions before 1.8.0 should use rbac.authorization.k8s.io/v1beta1

resource "kubernetes_cluster_role" "kube-state-metrics" {

  metadata {
    name = "kube-state-metrics"
  }

  rule {
    api_groups = [""]
    resources = ["configmaps",
                 "secrets",
                 "nodes",
                 "pods",
                 "services",
                 "resourcequotas",
                 "replicationcontrollers",
                 "limitranges",
                 "persistentvolumeclaims",
                 "persistentvolumes",
                 "namespaces",
                 "endpoints"
                 ]
    verbs = ["list", "watch"]

  }

  rule {
    api_groups = ["extensions"]
    resources = ["daemonsets",
                 "deployments",
                 "replicasets",
                 "ingresses"
                ]
    verbs = ["list", "watch"]
  }
  rule {
    api_groups = ["apps"]
    resources = ["daemonsets",
                 "deployments",
                 "replicasets",
                 "statefulsets"
                ]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = ["cronjobs", "jobs"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = ["horizontalpodautoscalers"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources = ["poddisruptionbudgets"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources = ["certificatesigningrequests"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources = ["storageclasses"]
    verbs = ["list", "watch"]
  }

  rule {
    api_groups = ["autoscaling.k8s.io"]
    resources = ["verticalpodautoscalers"]
    verbs = ["list", "watch"]
  }
}
