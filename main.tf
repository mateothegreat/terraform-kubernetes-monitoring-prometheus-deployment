resource "kubernetes_secret" "config" {

    metadata {

        namespace = var.namespace
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

    #    depends_on = [ kubernetes_secret.config, kubernetes_service.thanose-sidecar ]

    provider = kubernetes-alpha

    manifest = {

        apiVersion = "monitoring.coreos.com/v1"
        kind       = "Prometheus"

        metadata = {

            namespace = var.namespace
            name      = var.name

        }

        spec = {

            image              = "quay.io/prometheus/prometheus:${ var.prometheus_version }"
            replicas           = 1
            serviceAccountName = "prometheus-k8s"
            version            = var.prometheus_version
            name               = var.name
            namespace          = var.namespace
            nodeSelector       = var.prometheus_node_selector
            scrapeInterval     = var.prometheus_scrape_interval

            resources = {

                requests = {

                    memory = var.prometheus_request_memory
                    cpu    = var.prometheus_request_cpu

                }

                limits = {

                    memory = var.prometheus_limit_memory
                    cpu    = var.prometheus_limit_cpu

                }

            }

            storage = {

                volumeClaimTemplate = {

                    spec = {

                        storageClassName = "gp2"

                        resources = {

                            requests = {

                                storage = var.prometheus_storage

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

            #
            # External labels only apply when querying thanos externally.
            #
            externalLabels = var.external_labels

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

resource "kubernetes_service" "prometheus-ui" {

    count = var.prometheus_loadbalancer_enabled ? 1 : 0

    metadata {

        namespace = var.namespace
        name      = "${ var.name }-prometheus"

        labels = {

            app = "prometheus"

        }

        annotations = {

            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-internal" = var.prometheus_loadbalancer_internal ? "true" : null

        }

    }

    spec {

        type = "LoadBalancer"

        selector = {

            app = "prometheus"

        }

        port {

            name        = "http"
            port        = 9090
            target_port = "9090"

        }

    }

}

resource "kubernetes_service" "thanose-sidecar" {

    count = var.thanos_loadbalancer_enabled ? 1 : 0

    metadata {

        namespace = var.namespace
        name      = "${ var.name }-thanos-sidecar"

        labels = {

            app = "prometheus"

        }

        annotations = {

            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-internal" = var.thanos_loadbalancer_internal ? "true" : null

        }

    }

    spec {

        type = "LoadBalancer"

        selector = {

            app = "prometheus"

        }

        port {

            name        = "grpc"
            port        = 10901
            target_port = "grpc"

        }

        port {

            name        = "http"
            port        = 10902
            target_port = "http"

        }

    }

}
