# Forgejo Actions Go Base Image

This image is based on the [`catthehacker/ubuntu` image](https://github.com/catthehacker/docker_images/tree/master/linux/ubuntu) and imports Go tooling from the [`go-ubuntu-base` image](https://github.com/redjax/Dockerfiles/pkgs/container/dockerfiles%2Fgo-ubuntu-base).

This image is meant to be used as a [Forgejo Action runner](https://forgejo.org/docs/next/user/actions/reference/); use it in a pipeline like:

```yaml
jobs:
  build:
    runs-on: docker
    container:
      image: ghcr.io/redjax/dockerfiles/forgejo-go-base:24.04
    steps:
      - uses: actions/checkout@v6
      
      - name: Build
        run: go build -o myapp ./cmd/myapp
      
      - name: Lint
        run: golangci-lint run
      
      - name: Format
        run: goimports -w .
      
      - name: Release
        run: goreleaser release --skip-publish
```

## Build

```shell
docker build \
    --tag forgejo-go-base:24.04 \
    --build-arg UBUNTU_VERSION=24.04 \
    --build-arg BASE_IMG_VERSION=24.04 \
    --build-arg IMAGE_VERSION=24.04 \
    --build-arg IMAGE_CREATED="2026-06-20T23:00:00Z" \
    -f dockerfiles/ci/forgejo/base/go-base/Dockerfile \
    .
```
