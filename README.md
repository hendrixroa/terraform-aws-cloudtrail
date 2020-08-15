# Cloudtrail to S3 log

Module prebuilt for automate the cloudtrail tracking system to a S3 bucket.

- Terraform version:  `0.13.+`

## How to use

```hcl

module "cloudtrail" {
  source = "hendrixroa/cloudtrail/aws"

  enabled = var.aws_profile == "production" ? 1 : 0
  name    = "My awesome app"
}
```
