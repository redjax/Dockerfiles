# Go Ubuntu Base

An Ubuntu-based image with Go and some extra tooling.

Included tools:

- Go language
- [GoReleaser](https://github.com/goreleaser/goreleaser/)
- [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
- [golangci-lint](https://github.com/golangci/golangci-lint)

## Build

```shell
docker build \
    --tag go-ubuntu-base:1.0.0 \
    --build-arg UBUNTU_VERSION=24.04 \
    --build-arg GOLANG_VERSION=1.26.4 \
    --build-arg GORELEASER_VERSION=2.16.0 \
    --build-arg GOLANGCI_LINT_VERSION=2.12.2 \
    --build-arg GOIMPORTS_VERSION=v0.46.0 \
    --build-arg IMAGE_VERSION=1.0.0 \
    --build-arg IMAGE_CREATED="2026-06-20T23:00:00Z" \
    -f dockerfiles/base/ubuntu/go-base/Dockerfile \
    .
```

## Usage

```shell
# Run as a development container
docker run --rm -it go-ubuntu-base:1.0.0

# Use in a pipeline
docker run --rm go-ubuntu-base:1.0.0 \
    go build -o myapp ./cmd/myapp

# Run golangci-lint
docker run --rm -v .:/work go-ubuntu-base:1.0.0 \
    golangci-lint run

# Format code with goimports
docker run --rm -v .:/work go-ubuntu-base:1.0.0 \
    goimports -w .
```
