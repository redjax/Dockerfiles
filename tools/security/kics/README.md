# Tool: KICS

[KICS](https://github.com/Checkmarx/kics) is a code & vulnerability scanner for IaC. It can scan Terraform, Docker, Kubernetes, and more.

## Build

```shell
docker build \
    --tag kics:latest \
    --build-arg ALPINE_TAG=3.20
    --build-arg KICS_TAG=2.1.20 \
    .
```
