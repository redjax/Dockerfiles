# Base: Debian

Container image based on the [Debian image](https://hub.docker.com/_/debian).

Included packages:

- `curl`
- `ca-certificates`
- `git`
- `openssh-client`
- `jq`

## Build

```shell
docker build \
    --tag debian-base:bookworm-slim \
    --build-arg DEBIAN_TAG="bookworm-slim" \
    .
```
