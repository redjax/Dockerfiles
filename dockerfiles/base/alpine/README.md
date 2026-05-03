# Base: Alpine

Container image based on the [Alpine image](https://hub.docker.com/_/alpine).

Included packages:

- `bash`
- `curl`
- `ca-certificates`
- `git`
- `openssh-client`
- `jq`

## Build

```shell
docker build \
    --tag alpine-base:3.22.4 \
    --build-arg ALPINE_TAG="3.22.4" \
    .
```
