## https://docs.astral.sh/uv
ARG UV_BASE=0.11.21

## Base OS version
ARG DEBIAN_TAG=12.13

## Metadata defaults
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

## UV binary stage
FROM ghcr.io/astral-sh/uv:${UV_BASE} AS uv

## Base system layer
FROM debian:${DEBIAN_TAG}

ARG DEBIAN_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE
ARG UV_BASE

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_SYSTEM_PYTHON=1 \
    PATH="/root/.local/bin:${PATH}"

WORKDIR /work

## System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

## Install uv
COPY --from=uv /uv /usr/local/bin/uv

RUN chmod +x /usr/local/bin/uv \
    && uv --version

## Workspace structure
RUN mkdir -p /work

## Metadata
LABEL org.opencontainers.image.title="uv-base" \
      org.opencontainers.image.base.name="debian:${DEBIAN_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/astral-sh/uv" \
      org.opencontainers.image.description="Minimal base image with Astral uv installed and ready for Python project execution."

## Default shell
CMD ["/bin/bash"]