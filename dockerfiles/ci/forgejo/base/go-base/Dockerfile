###############################################
# Forgejo Actions base image for Golang apps. #
# Includes Go lang, tooling, & goreleaser.    #
###############################################

ARG UBUNTU_VERSION=24.04

## https://github.com/redjax/Dockerfiles/pkgs/container/dockerfiles%2Fgo-ubuntu-base
ARG BASE_IMG_VERSION=${UBUNTU_VERSION}

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

## Import from upstream image that has Go & Go tooling installed
FROM ghcr.io/redjax/dockerfiles/go-ubuntu-base:${BASE_IMG_VERSION} AS go-base
FROM ghcr.io/catthehacker/ubuntu:act-${UBUNTU_VERSION} AS base

## Import args from outer layer
ARG UBUNTU_VERSION
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

## Install base packages
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

FROM base AS runtime

ARG BASE_IMG_VERSION

## Copy Go installation from go-base image
COPY --from=go-base /usr/local/go /usr/local/go

## Copy Go tools from go-base image
COPY --from=go-base /usr/local/bin/goimports /usr/local/bin/goimports
COPY --from=go-base /usr/local/bin/golangci-lint /usr/local/bin/golangci-lint

## Copy GoReleaser from go-base image
COPY --from=go-base /usr/local/bin/goreleaser /usr/local/bin/goreleaser

## Set Go environment
ENV PATH="/usr/local/go/bin:/usr/local/bin:/root/go/bin:$PATH" \
    GOROOT="/usr/local/go" \
    GOPATH="/root/go" \
    GO111MODULE=auto

FROM runtime AS forgejo

## Verify all installations
RUN go version && \
    goimports -v && \
    golangci-lint version && \
    goreleaser --version

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="forgejo-go-base" \
      org.opencontainers.image.base.name="ghcr.io/catthehacker/ubuntu:act-${UBUNTU_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/ci/forgejo/base/go-base/README.md" \
      org.opencontainers.image.description="Forgejo Actions base image for Go workflows with Go, GoReleaser, goimports, and golangci-lint pre-installed, based on catthehacker/ubuntu."

CMD ["/bin/bash"]
