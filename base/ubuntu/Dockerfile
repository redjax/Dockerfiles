## https://hub.docker.com/_/ubuntu
ARG UBUNTU_TAG=26.04

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM ubuntu:${UBUNTU_TAG}

## Import args from outer layer
ARG UBUNTU_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="ubuntu-base" \
      org.opencontainers.image.base.name="ubuntu:${UBUNTU_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Minimal Ubuntu base image with additional tooling installed."

CMD ["/bin/bash"]
