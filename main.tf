provider "kubernetes" {

    host     = var.host
    token    = var.token
    insecure = var.insecure

}

provider "kubernetes-alpha" {

    host     = var.host
    token    = var.token
    insecure = var.insecure

}

resource "kubernetes_secret" "config" {

    metadata {

        namespace = "monitoring"
        name      = "thanos-objstore-config"

    }

    data = {

        "thanos.yaml" = jsonencode({

            type = "s3"

            config = {

                bucket     = var.s3_bucket
                endpoint   = var.s3_endpoint
                access_key = var.s3_aws_access_key_id
                secret_key = var.s3_aws_secret_access_key

            }

        })

    }

}

resource "kubernetes_manifest" "promethus-deployment" {

    provider = kubernetes-alpha

    manifest = {

        apiVersion = "monitoring.coreos.com/v1"
        kind       = "Prometheus"

        metadata = {

            namespace = "monitoring"
            name      = "k8s"

        }

        spec = {

            image              = "quay.io/prometheus/prometheus:v2.20.0"
            replicas           = 1
            serviceAccountName = "prometheus-k8s"
            version            = "v2.20.0"

            nodeSelector = {

                role = "services"

            }

            resources = {

                requests = {

                    memory = "200Mi"
                    cpu    = "1000m"

                }

            }

            storage = {

                volumeClaimTemplate = {

                    spec = {

                        storageClassName = "gp2"

                        resources = {

                            requests = {

                                storage = "40Gi"

                            }

                        }

                    }

                }

            }

            additionalScrapeConfigs = {

                name = "additional-scrape-configs"
                key  = "prometheus-additional.yaml"

            }

            ruleSelector = {

                matchLabels = {

                    prometheus = "k8s"
                    role       = "alert-rules"

                }

            }

            securityContext = {

                fsGroup      = 2000
                runAsNonRoot = true
                runAsUser    = 1000

            }

            externalLabels = {

                cluster     = var.cluster_name
                product     = var.product_name
                environment = var.environment_name

            }

            thanos = {

                baseImage           = "quay.io/thanos/thanos"
                version             = "v0.16.0"
                objectStorageConfig = {

                    key  = "thanos.yaml"
                    name = "thanos-objstore-config"

                }

            }

            alerting = {

                alertmanagers = [

                    {

                        name      = "alertmanager-main"
                        namespace = "monitoring"
                        port      = "web"

                    }

                ]

            }

            podMonitorNamespaceSelector     = {}
            podMonitorSelector              = {}
            probeNamespaceSelector          = {}
            probeSelector                   = {}
            serviceMonitorNamespaceSelector = {}
            serviceMonitorSelector          = {}

        }

    }

}

resource "kubernetes_service" "thanose-sidecar" {

    metadata {

        namespace = "monitoring"
        name = "thanos-sidecar"

        labels = {

            app = "prometheus"

        }

        annotations = {

            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-internal" = true

        }

    }

    spec {

        type = "LoadBalancer"

        selector = {

            app = "prometheus"

        }

        port {

            name = "grpc"
            port = 10901
            target_port = "grpc"

        }

        port {

            name = "http"
            port = 10902
            target_port = "http"

        }

    }

}
