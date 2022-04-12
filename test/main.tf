variable "cluster_name" {}

#
# Retrieve authentication for kubernetes from aws.
#
provider "aws" {}

#
# Get kubernetes cluster info.
#
data "aws_eks_cluster" "cluster" {

    name = var.cluster_name

}

#
# Retrieve authentication for kubernetes from aws.
#
data "aws_eks_cluster_auth" "cluster" {

    name = var.cluster_name

}

provider "kubernetes" {

    host  = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token

    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[ 0 ].data)

}

provider "kubernetes-alpha" {

    host  = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token

    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[ 0 ].data)

}

resource "kubernetes_secret" "additional-config" {

    metadata {

        name      = "additional-scrape-configs"
        namespace = "test-operator-1"

    }

    data = {

        "prometheus-additional.yaml" = ""

    }

}

module "monitoring-prometheus-deployment" {

    depends_on = [

        kubernetes_secret.additional-config

    ]

    source = "../"

    name                    = "test-1"
    prometheus_retention    = "7d"
    namespace               = "test-operator-1"
    prometheus_storage      = "10Gi"
    prometheus_limit_memory = "1024Mi"
    prometheus_scrape_interval = "5s"

    prometheus_loadbalancer_enabled  = true
    prometheus_loadbalancer_internal = true

    prometheus_node_selector = {

        role = "services"

    }

    external_labels = {

        cluster = "my-cluster-2"
        product = "api beep boop"

    }

}
