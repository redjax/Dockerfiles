# Base: Ubuntu

Container image based on the [Ubuntu image](https://hub.docker.com/_/ubuntu).

Included packages:

- `curl`
- `ca-certificates`
- `git`
- `openssh-client`
- `jq`

## Build

```shell
docker build \
    --tag ubuntu-base:26.04 \
    --build-arg UBUNTU_TAG="26.04" \
    .
```
