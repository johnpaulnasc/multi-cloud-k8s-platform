# =============================================================================
# OCI OKE Module
# =============================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_containerengine_cluster_option" "cluster_option" {
  cluster_option_id = "all"
}

locals {
  ads              = [for ad in data.oci_identity_availability_domains.ads.availability_domains : ad.name]
  k8s_versions     = data.oci_containerengine_cluster_option.cluster_option.kubernetes_versions
  latest_k8s_version = var.kubernetes_version != null ? var.kubernetes_version : element(local.k8s_versions, length(local.k8s_versions) - 1)
}

# -----------------------------------------------------------------------------
# OKE Cluster
# -----------------------------------------------------------------------------
resource "oci_containerengine_cluster" "main" {
  compartment_id     = var.compartment_id
  kubernetes_version = local.latest_k8s_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id

  cluster_pod_network_options {
    cni_type = var.cni_type
  }

  endpoint_config {
    is_public_ip_enabled = var.is_public_endpoint
    subnet_id            = var.public_subnet_ids[0]
    nsg_ids              = var.api_endpoint_nsg_ids
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = var.enable_kubernetes_dashboard
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = var.enable_pod_security_policy
    }

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    persistent_volume_config {
      freeform_tags = var.tags
    }

    service_lb_config {
      freeform_tags = var.tags
    }

    service_lb_subnet_ids = var.public_subnet_ids
  }

  type = var.cluster_type

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# OKE Node Pool
# -----------------------------------------------------------------------------
resource "oci_containerengine_node_pool" "main" {
  for_each = var.node_pools

  cluster_id     = oci_containerengine_cluster.main.id
  compartment_id = var.compartment_id
  name           = each.key

  kubernetes_version = local.latest_k8s_version

  node_config_details {
    size = each.value.node_count

    dynamic "placement_configs" {
      for_each = var.private_subnet_ids
      content {
        availability_domain = local.ads[placement_configs.key % length(local.ads)]
        subnet_id           = placement_configs.value
      }
    }

    nsg_ids = var.worker_nsg_ids

    freeform_tags = merge(var.tags, {
      "node-pool" = each.key
    })

    dynamic "node_pool_pod_network_option_details" {
      for_each = var.cni_type == "OCI_VCN_IP_NATIVE" ? [1] : []
      content {
        cni_type          = "OCI_VCN_IP_NATIVE"
        max_pods_per_node = each.value.max_pods_per_node
        pod_subnet_ids    = var.private_subnet_ids
        pod_nsg_ids       = var.worker_nsg_ids
      }
    }
  }

  node_shape = each.value.node_shape

  dynamic "node_shape_config" {
    for_each = each.value.is_flex_shape ? [1] : []
    content {
      memory_in_gbs = each.value.memory_in_gbs
      ocpus         = each.value.ocpus
    }
  }

  node_source_details {
    image_id                = each.value.image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = each.value.boot_volume_size_in_gbs
  }

  dynamic "initial_node_labels" {
    for_each = each.value.node_labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  ssh_public_key = var.ssh_public_key

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# Virtual Node Pool (Serverless - Optional)
# -----------------------------------------------------------------------------
resource "oci_containerengine_virtual_node_pool" "main" {
  for_each = var.virtual_node_pools

  cluster_id     = oci_containerengine_cluster.main.id
  compartment_id = var.compartment_id
  display_name   = each.key

  dynamic "placement_configurations" {
    for_each = var.private_subnet_ids
    content {
      availability_domain = local.ads[placement_configurations.key % length(local.ads)]
      fault_domain        = ["FAULT-DOMAIN-${(placement_configurations.key % 3) + 1}"]
      subnet_id           = placement_configurations.value
    }
  }

  pod_configuration {
    shape     = each.value.pod_shape
    subnet_id = var.private_subnet_ids[0]
    nsg_ids   = var.worker_nsg_ids
  }

  size = each.value.size

  dynamic "initial_virtual_node_labels" {
    for_each = each.value.node_labels
    content {
      key   = initial_virtual_node_labels.key
      value = initial_virtual_node_labels.value
    }
  }

  dynamic "taints" {
    for_each = each.value.taints
    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
  }

  freeform_tags = var.tags
}
