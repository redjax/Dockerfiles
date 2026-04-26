# Tool: Terraform

[Terraform](hashicorp.com/terraform) is a powerful tool for managing infrastructure as code.

## Build

```shell
docker build \
    --tag terraform:1.11.0 \
    --build-arg TERRAFORM_TAG=1.11.0 \
    --build-arg TFLINT_VERSION=0.62.0 \
    --build-arg TFSEC_VERSION=1.28.14 \
    .
```
