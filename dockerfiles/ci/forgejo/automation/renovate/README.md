# Forgejo: Renovate

This image uses the [`forgejo-runner-base` image](../../base/runner) as its base, inheriting all the tools and configurations from that image. This image has [Renovate](https://github.com/renovate-bot/renovate) pre-installed.

## Build

```shell
docker build \
    --tag forgejo-renovate:44.14.8 \
    --build-arg RENOVATE_VERSION=44.14.8 \
    .
```
