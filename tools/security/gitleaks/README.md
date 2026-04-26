# Tool: Gitleaks

[Gitleaks](https://github.com/gitleaks/gitleaks) is a Git repository secret scanner. It helps prevent API tokens and passwords from ending up in Git history.

## Build

```shell
docker build \
    --tag gitleaks:latest \
    --build-arg GITLEAKS_TAG=latest \
    .
```
