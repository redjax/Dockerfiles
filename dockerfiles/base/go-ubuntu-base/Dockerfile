###############################################
# Forgejo Actions base image for Golang apps. #
# Includes Go lang, tooling, & goreleaser.    #
###############################################

ARG UBUNTU_VERSION=24.04

## https://go.dev/dl/
ARG GOLANG_VERSION=1.26.4
## https://github.com/goreleaser/goreleaser/releases
ARG GORELEASER_VERSION=2.16.0
## https://github.com/golangci/golangci-lint/releases
ARG GOLANGCI_LINT_VERSION=2.12.2
## https://pkg.go.dev/golang.org/x/tools/cmd/goimports
ARG GOIMPORTS_VERSION=v0.46.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM ubuntu:${UBUNTU_VERSION} AS base

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

FROM base AS go

ARG GOLANG_VERSION

## Install Go
RUN curl -fsSL "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local

## Set Go environment
ENV PATH="/usr/local/go/bin:$PATH" \
    GOROOT="/usr/local/go" \
    GOPATH="/root/go" \
    GO111MODULE=auto

## Set Go environment (inherited by go-tools, goreleaser, runtime layers)
ENV PATH="/usr/local/go/bin:/usr/local/bin:/root/go/bin:$PATH" \
    GOROOT="/usr/local/go" \
    GOPATH="/root/go" \
    GO111MODULE=auto

## Verify Go installation
RUN go version

FROM go AS go-tools

ARG GOIMPORTS_VERSION
ARG GOLANGCI_LINT_VERSION

## Install goimports (formatting & import management)
RUN go install golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION} && \
    install -m 0755 /root/go/bin/goimports /usr/local/bin/goimports

## Install golangci-lint
RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    curl -fsSLO "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz"; \
    tar -xzf golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz --strip-components=1; \
    install -m 0755 golangci-lint /usr/local/bin/golangci-lint; \
    rm -rf "$tmpdir"

## Verify tools installation
RUN goimports -v && golangci-lint version

FROM go-tools AS goreleaser

ARG GORELEASER_VERSION

## Install GoReleaser
RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    curl -fsSLO "https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz"; \
    tar -xzf goreleaser_Linux_x86_64.tar.gz; \
    install -m 0755 goreleaser /usr/local/bin/goreleaser; \
    rm -rf "$tmpdir"

## Verify GoReleaser installation
RUN goreleaser --version

FROM goreleaser AS runtime

## Verify all installations
RUN go version && \
    goimports -v && \
    golangci-lint version && \
    goreleaser --version

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="go-ubuntu-base" \
      org.opencontainers.image.base.name="ubuntu:${UBUNTU_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/base/go-ubuntu-base/README.md" \
      org.opencontainers.image.description="Container with Go and supporting tools like GoReleaser."

CMD ["/bin/bash"]
