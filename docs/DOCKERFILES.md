# Dockerfiles <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->

- [Image metadata labels](#image-metadata-labels)
  - [Examples](#examples)
    - [Debian Dockerfile with opencontainers labels](#debian-dockerfile-with-opencontainers-labels)
- [Renovate Comments](#renovate-comments)
  - [Renovate Docker tags](#renovate-docker-tags)
  - [Renovate tool versions](#renovate-tool-versions)
  - [Renovate both Docker tags and tool versions](#renovate-both-docker-tags-and-tool-versions)

## Image metadata labels

The [`LABEL` keyword](https://docs.docker.com/reference/dockerfile/#label) adds key/value metadata pairs to an image. Some code forges like Github allow [labels to annotate images published to their container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#labelling-container-images).

### Examples

#### Debian Dockerfile with opencontainers labels

Before labels, this image builds a Debian container from the upstream Debian image and adds some extra tooling:

```dockerfile
## https://hub.docker.com/_/debian
ARG DEBIAN_TAG=latest

FROM debian:${DEBIAN_TAG}

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

CMD ["/bin/bash"]

```

But we can add [opencontainer labels](https://specs.opencontainers.org/image-spec/annotations/#pre-defined-annotation-keys). This example adds the following:

- `org.opencontainers.image.title="debian-base"`: The human-readable title of the image.
- `org.opencontainers.image.base.name="debian:${DEBIAN_TAG}"`: The image reference of the image this image is based on.
- `org.opencontainers.image.version="${IMAGE_VERSION}"`: The versionn of the packaged software.
- `org.opencontainers.image.created="${IMAGE_CREATED}"`: The datetime when the image was built.
- `org.opencontainers.image.source="${IMAGE_SOURCE}"`: URL to the source code for the image.
- `org.opencontainers.image.description="Minimal Debian base image with additional tooling installed."`: Human-readable description of the image (max 512 chars).

Defining these values as `ARG` lets you pass them from a script with `--build-arg ARG_NAME=value`, or in a pipeline/compose file. The args must be imported in the final stage so they're available for the `LABEL` instruction.

```dockerfile
## https://hub.docker.com/_/debian
ARG DEBIAN_TAG=latest

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

## Metadata
LABEL org.opencontainers.image.title="debian-base" \
      org.opencontainers.image.base.name="debian:${DEBIAN_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Minimal Debian base image with additional tooling installed."

CMD ["/bin/bash"]

```

## Renovate Comments

This repository uses [`renovate`](https://www.mend.io/mend-renovate/) to bump dependency and Docker image versions. The [`renovate.yml` pipeline](../.github/workflows/renovate.yml) runs nightly or on demand, and it uses the `dockerfile` manager and custom regular expressions for the `image.yml` files to bump dependency versions.

The regular expressions will automatically work on `image.yml` manifests. The Dockerfiles use `ARG` lines to declare version numbers. You need to use Renovate comment markers to tell Renovate what to bump, and how.

### Renovate Docker tags

A Dockerfile using Alpine Linux as a base might look like:

```dockerfile
ARG ALPINE_TAG=3.22.4

FROM alpine:${ALPINE_TAG} AS base

...
```

To tell Renovate to watch the `ALPINE_TAG` arg, you can add a comment like `# renovate: datasource=docker depName=alpine versioning=semver`:

```dockerfile
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.22.4

FROM alpine:${ALPINE_TAG} AS base
```

### Renovate tool versions

Some Dockerfiles include a tool version arg too. For example, the [Taskfile Docker image](../dockerfiles/automation/taskfile/Dockerfile) has an `ARG TASKFILE_VERSION=v3.50.0`. The Renovate comment marker for this would be `# renovate: datasource=github-releases depName=go-task/task extractVersion=^v(?<version>.*)$`:

```dockerfile
# renovate: datasource=github-releases depName=go-task/task extractVersion=^v(?<version>.*)$
ARG TASKFILE_VERSION=v3.50.0

RUN curl -fsSL \
      "https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz" \
      -o /tmp/taskfile.tar.gz \
    && mkdir /tmp/taskfile \
    && tar -xzvf /tmp/taskfile.tar.gz -C /tmp/taskfile \
    && chmod +x /tmp/taskfile/task \
    && mv /tmp/taskfile/task /usr/local/bin/task \
    && rm -rf /tmp/taskfile /tmp/taskfile.tar.gz
```

### Renovate both Docker tags and tool versions

For images that have both Docker image tags and tool versions, i.e. the [`base/go-ubuntu-base` image](../dockerfiles/base/go-ubuntu-base/Dockerfile), you can use both types of comments:

```dockerfile
# renovate: datasource=docker depName=ubuntu versioning=semver
ARG UBUNTU_VERSION=24.04

# renovate: datasource=github-releases depName=golang/go extractVersion=^go(?<version>.*)$
ARG GOLANG_VERSION=1.26.4

# renovate: datasource=github-releases depName=goreleaser/goreleaser extractVersion=^v(?<version>.*)$
ARG GORELEASER_VERSION=2.16.0

FROM ubuntu:${UBUNTU_VERSION} AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    tar \
    gzip \
    unzip \
    openssh-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work

FROM base AS go

ARG GOLANG_VERSION

RUN curl -fsSL "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local

ENV PATH="/usr/local/go/bin:$PATH" \
    GOROOT="/usr/local/go" \
    GOPATH="/root/go" \
    GO111MODULE=auto

FROM go AS goreleaser

ARG GORELEASER_VERSION

RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    curl -fsSLO "https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz"; \
    tar -xzf goreleaser_Linux_x86_64.tar.gz; \
    install -m 0755 goreleaser /usr/local/bin/goreleaser; \
    rm -rf "$tmpdir"

ENTRYPOINT ["/usr/local/bin/goreleaser"]
CMD ["--version"]
```
