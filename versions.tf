terraform {
  required_version = ">= 1.14.0"

  required_providers {
    juju = {
      source  = "juju/juju"
      version = "> 1.3"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0"
    }
  }
}
