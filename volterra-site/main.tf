terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~>0.3"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = format("https://%s.console.ves.volterra.io/api", var.tenant)
}

resource "volterra_aws_vpc_site" "aws_site" {
  name            = var.site_name
  namespace       = "system"
  aws_region      = var.region
  no_worker_nodes = true

  // One of the arguments from this list "aws_cred assisted" must be set

  aws_cred {
    name      = var.aws_creds
    namespace = "system"
    tenant    = var.tenant_id
  }

  vpc {
    new_vpc {
      name_tag      = format("%s-vpc", var.site_name)
      primary_ipv4  = var.vpc_cidr
      allocate_ipv6 = "false"
    }
  }

  instance_type           = "t3.xlarge"
  logs_streaming_disabled = true

  ingress_egress_gw {
    aws_certified_hw = "aws-byol-multi-nic-voltmesh"

    az_nodes {
      aws_az_name            = var.az
      reserved_inside_subnet = true
      disk_size              = 120

      outside_subnet {
        subnet_param {
          ipv4 = cidrsubnet(var.vpc_cidr, 8, 0)
        }
      }

      workload_subnet {
        subnet_param {
          ipv4 = cidrsubnet(var.vpc_cidr, 8, 1)
        }
      }
    }

    no_forward_proxy = true

    no_network_policy = true

    no_outside_static_routes = true

    global_network_list {
      global_network_connections {
        sli_to_global_dr {
          global_vn {
            name      = var.global_network
            namespace = "system"
          }
        }
      }
    }

    inside_static_routes {
      static_route_list {
        simple_static_route = var.vpc_cidr
      }
    }
  }
}

resource "volterra_tf_params_action" "aws_site" {
  depends_on      = [volterra_aws_vpc_site.aws_site]
  site_name       = var.site_name
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true
}
