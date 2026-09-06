# Dockerfiles <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->

- [Image structure](#image-structure)
- [Image metadata](#image-metadata)
  - [Metadata example](#metadata-example)
- [Image labels](#image-labels)
  - [Metadata arguments](#metadata-arguments)
  - [Example Dockerfile](#example-dockerfile)
- [Renovate comments](#renovate-comments)
  - [Docker image versions](#docker-image-versions)
  - [GitHub release versions](#github-release-versions)
  - [Go module versions](#go-module-versions)
  - [Multiple dependencies](#multiple-dependencies)
- [Building images](#building-images)

## Image structure

Each image is stored in its own directory below `dockerfiles/`.

An image directory contains a Dockerfile and a metadata file:

```text
dockerfiles/<category>/<image>/
├── Dockerfile
├── metadata.yml
└── README.md
```

For example:

```text
dockerfiles/automation/taskfile/
├── Dockerfile
├── metadata.yml
└── README.md
```

The image directory is used as the Docker build context. The build scripts locate images by finding directories that contain both `Dockerfile` and `metadata.yml`.

## Image metadata

Each image has a `metadata.yml` file containing static information used by the build and publishing scripts. Dependency versions are not stored in `metadata.yml`. They are declared in the Dockerfile and updated there by Renovate.

### Metadata example

```yaml
***
name: taskfile
category: automation
description: Alpine image with Taskfile installed for build automation.
publish: true
registry_path: ghcr.io/redjax/dockerfiles/taskfile
```

The metadata fields are:

| Field           | Description                                        |
| --------------- | -------------------------------------------------- |
| `name`          | Local image name used during the build.            |
| `category`      | Image category.                                    |
| `description`   | Human-readable image description.                  |
| `publish`       | Whether the image may be published to GHCR.        |
| `registry_path` | Full container registry path used when publishing. |

The metadata file does not contain:

- Dependency versions.
- Docker build arguments.
- Dockerfile paths.
- Build contexts.
- Renovate configuration.

Those values are derived from the image directory or declared directly in the Dockerfile.

## Image labels

The [`LABEL` instruction](https://docs.docker.com/reference/dockerfile/#label) adds metadata to an image. This repository uses the predefined [Open Containers image annotations](https://specs.opencontainers.org/image-spec/annotations/#pre-defined-annotation-keys).

### Metadata arguments

Images use the following common build arguments:

```dockerfile
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"
```

The build scripts override these values when building images in CI. The arguments must be declared again after the final `FROM` instruction before they can be used by `LABEL`:

```dockerfile
FROM alpine:${ALPINE_TAG}

ARG ALPINE_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE
```

The common labels are:

| Label                                    | Description                                          |
| ---------------------------------------- | ---------------------------------------------------- |
| `org.opencontainers.image.title`         | Human-readable image name.                           |
| `org.opencontainers.image.base.name`     | Base image reference.                                |
| `org.opencontainers.image.version`       | Version or build identifier for the resulting image. |
| `org.opencontainers.image.created`       | UTC image creation timestamp.                        |
| `org.opencontainers.image.source`        | Source repository URL.                               |
| `org.opencontainers.image.documentation` | Documentation URL for the image.                     |
| `org.opencontainers.image.description`   | Human-readable image description.                    |

### Example Dockerfile

```dockerfile
## [https://hub.docker.com/_/debian](https://hub.docker.com/_/debian)
# renovate: datasource=docker depName=debian versioning=semver
ARG DEBIAN_TAG=13.3

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM debian:${DEBIAN_TAG}

## Import args from outer layer
ARG DEBIAN_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

LABEL org.opencontainers.image.title="debian-base" \
      org.opencontainers.image.base.name="debian:${DEBIAN_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Minimal Debian base image with additional tooling installed."

CMD ["/bin/bash"]
```

## Renovate comments

This repository uses [Renovate](https://github.com/renovatebot/renovate) to update:

- Docker base image tags.
- Go versions.
- GitHub release versions.
- GitHub tag versions.
- GitHub Actions.

Renovate updates dependency values directly in Dockerfiles. Each versioned `ARG` is preceded by a Renovate comment that identifies its datasource and dependency.

Renovate processes Dockerfiles with its Dockerfile manager and uses the repository’s custom regex manager for versioned Dockerfile arguments.

### Docker image versions

A Docker base image version is declared with a Docker datasource comment:

```dockerfile
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1

FROM alpine:${ALPINE_TAG}
```

The `ARG` value is used by the `FROM` instruction and is updated by Renovate when a newer matching image tag is available.

### GitHub release versions

Tools distributed through GitHub Releases generally use release tags beginning with `v`. The Dockerfile stores the version without the prefix:

```dockerfile
# renovate: datasource=github-releases depName=go-task/task extractVersion=^v(?<version>.*)$
ARG TASKFILE_VERSION=3.53.1
```

The prefix is added when constructing the download URL:

```dockerfile
RUN curl --fail --show-error --location \
      "https://github.com/go-task/task/releases/download/v${TASKFILE_VERSION}/task_linux_amd64.tar.gz" \
      --output /tmp/taskfile.tar.gz \
    && mkdir -p /tmp/taskfile \
    && tar --extract \
      --gzip \
      --file /tmp/taskfile.tar.gz \
      --directory /tmp/taskfile \
    && install \
      --mode=0755 \
      /tmp/taskfile/task \
      /usr/local/bin/task \
    && rm -rf \
      /tmp/taskfile.tar.gz \
      /tmp/taskfile
```

The `extractVersion` expression removes the leading `v` from the release tag before writing the value to the Dockerfile.

### Go module versions

Go module versions are also commonly tagged with a leading `v`.

For example, the `goimports` version is stored without the prefix:

```dockerfile
# renovate: datasource=github-tags depName=golang/tools versioning=semver extractVersion=^v(?<version>.*)$
ARG GOIMPORTS_VERSION=0.49.0
```

The prefix is added when installing the module:

```dockerfile
RUN go install \
      "golang.org/x/tools/cmd/goimports@v${GOIMPORTS_VERSION}" \
    && install \
      -m 0755 \
      /root/go/bin/goimports \
      /usr/local/bin/goimports
```

This allows Renovate to update the Dockerfile value while preserving the version format required by `go install`.

### Multiple dependencies

An image can contain multiple Renovate-managed dependencies. Each dependency has its own comment and `ARG`.

```dockerfile
# renovate: datasource=docker depName=ubuntu versioning=semver
ARG UBUNTU_VERSION=26.10

# renovate: datasource=github-releases depName=golang/go extractVersion=^go(?<version>.*)$
ARG GOLANG_VERSION=1.26.4

# renovate: datasource=github-releases depName=goreleaser/goreleaser extractVersion=^v(?<version>.*)$
ARG GORELEASER_VERSION=2.16.0

# renovate: datasource=github-releases depName=golangci/golangci-lint extractVersion=^v(?<version>.*)$
ARG GOLANGCI_LINT_VERSION=2.13.1

# renovate: datasource=github-tags depName=golang/tools versioning=semver extractVersion=^v(?<version>.*)$
ARG GOIMPORTS_VERSION=0.49.0
```

The arguments are then used by the relevant build steps:

```dockerfile
FROM ubuntu:${UBUNTU_VERSION} AS base
```

```dockerfile
RUN curl --fail --show-error --location \
      "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" \
      --output /tmp/go.tar.gz \
    && tar --extract \
      --gzip \
      --file /tmp/go.tar.gz \
      --directory /usr/local \
    && rm -f /tmp/go.tar.gz
```

```dockerfile
RUN go install \
      "golang.org/x/tools/cmd/goimports@v${GOIMPORTS_VERSION}" \
    && install \
      -m 0755 \
      /root/go/bin/goimports \
      /usr/local/bin/goimports
```

```dockerfile
RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    curl --fail --show-error --location \
      "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz" \
      --output golangci-lint.tar.gz; \
    tar --extract \
      --gzip \
      --file golangci-lint.tar.gz \
      --strip-components=1; \
    install \
      -m 0755 \
      golangci-lint \
      /usr/local/bin/golangci-lint; \
    rm -rf "$tmpdir"
```

Each Renovate comment should be immediately above the `ARG` it manages.

## Building images

The build scripts use the following process:

1. Discover image directories containing `Dockerfile` and `metadata.yml`.
2. Compare two Git revisions to identify changed files.
3. Select image directories containing changed files.
4. Read static image metadata from `metadata.yml`.
5. Build the selected images using their directories as build contexts.
6. Add common OCI metadata arguments.
7. Publish images whose metadata has `publish: true` when publishing is enabled.

To build one image locally:

```bash
./scripts/build/build-image.sh \
  --image-dir dockerfiles/automation/taskfile \
  --tag local \
  --pull
```

To determine changed images:

```bash
./scripts/build/determine-images-to-build.sh \
  --base HEAD^ \
  --head HEAD \
  --output build_list.txt
```

To build the selected images without publishing:

```bash
./scripts/build/build-and-publish-images.sh \
  --pull \
  build_list.txt
```

To build and publish the selected images:

```bash
./scripts/build/build-and-publish-images.sh \
  --pull \
  --publish \
  build_list.txt
```

To select every image:

```bash
./scripts/build/determine-images-to-build.sh \
  --force \
  --output build_list.txt
```

The resulting `build_list.txt` contains one image directory per line:

```text
dockerfiles/automation/taskfile
dockerfiles/base/go-ubuntu-base
```
