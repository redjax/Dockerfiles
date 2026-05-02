# Tool: Trivy

[Trivy](https://trivy.dev) is an all-in-one security and CVE scanner.

## Build

```shell
docker build \
    --tag trivy:latest \
    --build-arg TRIVY_TAG=latest \
    .
```
