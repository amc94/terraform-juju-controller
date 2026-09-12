provider "juju" {
  controller_mode = true
}

resource "juju_controller" "controller" {
  juju_binary = var.path_juju_binary
  name        = var.name

  cloud            = var.cloud
  cloud_credential = var.cloud_credential

  agent_version           = var.agent_version
  bootstrap_base          = var.bootstrap_base
  bootstrap_config        = var.bootstrap_config
  bootstrap_constraints   = var.bootstrap_constraints
  controller_config       = var.controller_config
  controller_model_config = var.controller_model_config
  destroy_flags           = var.destroy_flags
  model_constraints       = var.model_constraints
  model_default           = var.model_default
  storage_pool            = var.storage_pool

  lifecycle {
    action_trigger {
      events    = [after_create]
      condition = var.controller_num_units > 1
      actions   = [action.juju_enable_ha.ha]
    }
  }
}

action "juju_enable_ha" "ha" {
  config {
    api_addresses = caller.api_addresses
    ca_cert       = caller.ca_cert
    username      = caller.username
    password      = caller.password
    units         = var.controller_num_units
  }
}
