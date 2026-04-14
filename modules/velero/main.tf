resource "kubernetes_namespace" "velero" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "velero" {
  name       = var.release_name
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = var.chart_version
  namespace  = kubernetes_namespace.velero.metadata[0].name

  set {
    name  = "configuration.backupStorageLocation[0].name"
    value = "default"
  }

  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = var.bucket_name
  }

  set {
    name  = "configuration.backupStorageLocation[0].default"
    value = "true"
  }

  set {
    name  = "configuration.backupStorageLocation[0].config.region"
    value = "minio"
  }

  set {
    name  = "configuration.backupStorageLocation[0].config.s3ForcePathStyle"
    value = "true"
  }

  set {
    name  = "configuration.backupStorageLocation[0].config.s3Url"
    value = var.s3_url
  }

  set {
    name  = "credentials.useSecret"
    value = "true"
  }

  set_sensitive {
    name  = "credentials.secretContents.cloud"
    value = <<-EOT
[default]
aws_access_key_id=${var.access_key}
aws_secret_access_key=${var.secret_key}
EOT
  }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.10.1"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }

  wait    = true
  timeout = 600
}