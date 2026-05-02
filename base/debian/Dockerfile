## https://hub.docker.com/_/debian
ARG DEBIAN_TAG=12.13

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
