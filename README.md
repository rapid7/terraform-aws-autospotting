# AutoSpotting

Automatically convert your existing Auto Scaling groups to significantly cheaper spot instances with minimal (often zero) configuration changes.

See [https://github.com/autospotting/autospotting](https://github.com/autospotting/autospotting) for details.

## Using the terraform-aws-autospotting module

- [AutoSpotting](#autospotting)
  - [Using the terraform-aws-autospotting module](#using-the-terraform-aws-autospotting-module)
    - [Sources](#sources)
    - [Setting variables](#setting-variables)
    - [Multiple installations](#multiple-installations)
    - [Logs or Troubleshooting](#logs-or-troubleshooting)

### Sources

This module can be used from the Terraform Registry or directly from this
repository.

The installer defaults to the latest stable version of AutoSpotting available on
the AWS Marketplace. In order to use it you first need to
[subscribe](https://aws.amazon.com/marketplace/pp/prodview-6uj4pruhgmun6) to
it.

Alternatively you can build your own image as described in the
[documentation](https://github.com/AutoSpotting/AutoSpotting/blob/master/CUSTOM_BUILDS.md),
but this comes without any support unless you're trying to contribute code via pull
requests.

Using from the Terraform Registry:

```hcl
module "autospotting" {
  source  = "AutoSpotting/autospotting/aws"
  # version = "0.1.2"
}
```

Using from this repository:

```hcl
module "autospotting" {
  source = "github.com/autospotting/terraform-aws-autospotting?ref=master" # or ref=0.1.2, etc.
}
```

Notes:

- If the first run gives this error message `Error: Provider produced
  inconsistent final plan`, this is expected because we generate a Dockerfile
  from Terraform (it's a long story). Just re-run Terraform and it should work
  on a second run. Sorry about this!
- At runtime the code will run against all other enabled regions.
- New releases of this module have been tested with Terraform 1.0 or newer, YMMV
  with older versions.

### Setting variables

Available variables are defined in the [variables file](variables.tf). To change the defaults, just pass in the relevant variables:

```hcl
module "autospotting" {
  source                                = "github.com/autospotting/terraform-aws-autospotting"
  autospotting_min_on_demand_percentage = "33.3"
  lambda_memory_size                    = 1024
}
```

Or you can pass them in on the command line:

``` shell
 terraform apply \
   -var autospotting_min_on_demand_percentage="33.3" \
   -var lambda_memory_size=1024
```

### Multiple installations

You can change the names of the resources terraform will create – or run multiple instances of autospotting that target different ASGs – by using the label variables:

```hcl
module "autospotting_storage" {
  source                              = "github.com/autospotting/terraform-aws-autospotting"
  label_name                          = "autospotting_storage"
  autospotting_allowed_instance_types = "i3.*"
  autospotting_tag_filters            = "spot-enabled=true,storage-optimized=true,"
}

module "autospotting_dev_memory" {
  source                              = "github.com/autospotting/terraform-aws-autospotting"
  label_name                          = "autospotting_memory"
  label_environment                   = "dev"
  autospotting_allowed_instance_types = "r5*"
  autospotting_tag_filters            = "spot-enabled=true,memory-optimized=true,environment=dev,"
}
```

### Logs or Troubleshooting

To check logs and troubleshoot issues, you can go to the `/aws/lambda/<your_lambda_function_name>` CloudWatch Log group.
