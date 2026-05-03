# Dockerfiles <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->

- [Image metadata labels](#image-metadata-labels)
  - [Examples](#examples)
    - [Debian Dockerfile with opencontainers labels](#debian-dockerfile-with-opencontainers-labels)

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
