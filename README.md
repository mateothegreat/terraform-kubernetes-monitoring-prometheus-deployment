# Prometheus operator based deployment

## Resourcing

See https://www.robustperception.io/how-much-ram-does-prometheus-2-x-need-for-cardinality-and-ingestion
for calculating resource requirements.

Notes:

* It will take at least 512Mi to scrape the basics (apiserver, kubelet, etc).
* Get the top most counts via `topk(10, count by (job)({__name__=~".+"}))`.

### Getting the usage of promtetheus

#### What is my top metrics by count

```prometheus
topk(10, count by (__name__)({__name__=~".+"}))
```

#### Memory usage

```prometheus
avg(
    (avg(container_memory_working_set_bytes{pod="prometheus-test-1-0"}) by (container_name, pod)) / on 
    (container_name, pod) (avg(container_spec_memory_limit_bytes > 0) by (container_name, pod)) * 100
)
```

### Set up the aws provider (optional)

```hcl-terraform

#
# Retrieve authentication for kubernetes from aws.
#
provider "aws" {

    profile = var.aws_profile
    region  = var.aws_region

}

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
```

In this example the outputs of `aws_eks_cluster` and `aws_eks_cluster_auth` are consumed
below when we set up the kubrernetes providers.

### Set up the kubernetes provider

```hcl-terraform
provider "kubernetes" {

    host     = var.host
    token    = var.token
    insecure = var.insecure

}
```

### Set up the kubernetes-alpha provider

This is used because the module itself depends on the ability to
manage custom CRD objects.

```hcl-terraform
provider "kubernetes-alpha" {

    host     = var.host
    token    = var.token
    insecure = var.insecure

}
```

### Set up the module

This is a sampled down example below
(see https://registry.terraform.io/modules/mateothegreat/monitoring-prometheus-deployment/kubernetes/latest?tab=inputs
for all the inputs).

```hcl-terraform
module "monitoring-prometheus-deployment" {

    source  = "mateothegreat/monitoring-prometheus-deployment/kubernetes"
    version = "<insert latest version here>"
    
    prometheus_retention    = "7d"
    prometheus_storage      = "10Gi"
    
    prometheus_node_selector = {
    
        role = "services"
        
    }
    
    external_labels = {
        
        cluster = "my-cluster-2"
        product = "api beep boop"
    
    }

}
```
