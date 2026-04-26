# Tool: Trufflehog

[Trufflehog](https://github.com/trufflesecurity/trufflehog) scans a Git repository for credentials & other secrets.

## Build

```shell
docker build \
    --tag trufflehog:latest \
    --build-arg TRUFFLEHOG_TAG=latest \
    .
```
