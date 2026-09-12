# terraform-juju-controller

Terraform module to bootstrap a [Juju](https://juju.is) controller.


## Usage

The module bootstraps a Juju controller and, when `controller_num_units > 1`, enables HA.
Inputs and outputs map directly onto the `juju_controller` resource. For the authoritative
reference, see the upstream docs:
[Bootstrap a controller](https://canonical.com/juju/docs/terraform-provider-juju/2.0/howto/manage-controllers/#bootstrap-a-controller).

```hcl
module "controller" {
  source  = "juju/juju-controller/juju"

  name                 = "my-controller"
  controller_num_units = 1

  cloud = {
    name       = "localhost"
    type       = "lxd"
    auth_types = ["certificate"]
  }

  cloud_credential = {
    name      = "my-credential"
    auth_type = "certificate"
    attributes = {
      server-cert = "..."
      client-cert = "..."
      client-key  = "..."
    }
  }
}
```

### Example: LXD cloud

```hcl
module "controller" {
  source  = "juju/juju-controller/juju"

  name = "my-controller"

  cloud = {
    auth_types = ["certificate"]
    name       = "lxd-cloud"
    type       = "lxd"
    endpoint   = "https://10.0.0.1:8443"
    region = {
      name     = "default"
      endpoint = "https://10.0.0.1:8443"
    }
  }

  cloud_credential = {
    auth_type = "interactive"
    name      = "lxd-token"
    attributes = {
      trust-token = trimspace(file("/path/to/token"))
    }
  }

  controller_num_units = 3
}
```

### Example: MAAS cloud

```hcl
module "controller" {
  source  = "juju/juju-controller/juju"

  name = "my-controller"

  cloud = {
    auth_types = ["oauth1"]
    type       = "maas"
    name       = "maas-cloud"
    endpoint   = "http://10.0.0.1:5240/MAAS/"
  }

  cloud_credential = {
    auth_type = "oauth1"
    name      = "maas-creds"
    attributes = {
      maas-oauth = trimspace(file("/path/to/maas_api_key"))
    }
  }

  controller_num_units = 3
}
```

See `variables.tf` and `outputs.tf` for the full input/output set.

## Terragrunt unit

The Terragrunt unit is available at [`terragrunt/units/juju_bootstrap`](https://github.com/juju/terraform-juju-controller/tree/main/terragrunt/units/juju_bootstrap). It is designed for use with [Terragrunt stacks](https://docs.terragrunt.com/reference/hcl/blocks/#unit) and reads its configuration from a `values` map provided by the enclosing stack.

Create a `terragrunt.stack.hcl` file that declares the unit and provides `values`:

```hcl
unit "controller" {
  source = "git::https://github.com/juju/terraform-juju-controller.git//terragrunt/units/juju_bootstrap?ref=main"
  path   = "controller"

  values = {
    version              = "0.0.1-rc4"
    name                 = "my-controller"
    controller_num_units = 1

    cloud = {
      name       = "localhost"
      type       = "lxd"
      auth_types = ["certificate"]
    }

    cloud_credential = {
      name      = "my-credential"
      auth_type = "certificate"
      attributes = {
        server-cert = "..."
        client-cert = "..."
        client-key  = "..."
      }
    }
  }
}
```

Then generate and apply the stack:

```bash
terragrunt stack run -- apply
```

## High availability

`controller_num_units > 1` enables HA via the `juju_enable_ha` action triggered during bootstrap.

## Notes

- HA enablement relies on Terraform actions (`action.juju_enable_ha`), which requires Terraform 1.14 or later. See <https://canonical.com/juju/docs/terraform-provider-juju/latest/howto/manage-controllers/#enable-controller-high-availability>.
