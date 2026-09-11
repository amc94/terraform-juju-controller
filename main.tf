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
}

# TODO: Terraform actions are available to enable HA, however actions are not yet supported by OpenTofu, thus we stick with local-exec for now.
# https://documentation.ubuntu.com/terraform-provider-juju/v1.4.3/howto/manage-controllers/#enable-controller-high-availability
resource "terraform_data" "juju_enable_ha" {
  count = var.controller_num_units > 1 ? 1 : 0
  provisioner "local-exec" {
    command = <<-EOT
      set -eu

      JUJU_MAJOR_VERSION=$("$JUJU_BINARY" version | sed -n 's/^\([0-9][0-9]*\)\..*/\1/p')
      if [ -z "$JUJU_MAJOR_VERSION" ]; then
        echo "Unable to determine Juju major version." >&2
        exit 1
      fi

      echo "$JUJU_PASSWORD" | "$JUJU_BINARY" login -c "$CONTROLLER_NAME" "$JUJU_CONTROLLER" -u "$JUJU_USERNAME" --trust --no-prompt

      if [ "$JUJU_MAJOR_VERSION" -ge 4 ]; then
        "$JUJU_BINARY" add-unit -m "$CONTROLLER_NAME":controller controller -n "$((HA_COUNT - 1))"
      else
        "$JUJU_BINARY" enable-ha -c "$CONTROLLER_NAME" -n "$HA_COUNT"
      fi

      "$JUJU_BINARY" wait-for model "$CONTROLLER_NAME":controller --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active"))'
    EOT
    environment = {
      JUJU_BINARY     = var.path_juju_binary
      CONTROLLER_NAME = juju_controller.controller.name
      JUJU_CONTROLLER = juju_controller.controller.api_addresses[0]
      JUJU_USERNAME   = juju_controller.controller.username
      JUJU_PASSWORD   = juju_controller.controller.password
      HA_COUNT        = var.controller_num_units
    }
  }
}
