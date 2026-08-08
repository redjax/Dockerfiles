###############################################
# Forgejo Actions universal runner base image #
#                                             #
# Includes tooling most pipelines would need, #
# like node/npm, curl/wget, build tooling,    #
# ssh, docker.io client, and more.            #
###############################################

# renovate: datasource=docker depName=ubuntu
ARG UBUNTU_VERSION=26.10

# renovate: datasource=golang-version depName=go
ARG GO_VERSION=1.25.6

FROM ubuntu:${UBUNTU_VERSION} AS base

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC

## Install OS packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    git-lfs \
    openssh-client \
    sudo \
    locales \
    tzdata \
    jq \
    yq \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zip \
    unzip \
    p7zip-full \
    build-essential \
    make \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    rsync \
    file \
    patch \
    diffutils \
    gettext \
    gnupg \
    openssl \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

## Runner user
RUN useradd \
    --create-home \
    --shell /bin/bash \
    --groups sudo \
    runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" \
       > /etc/sudoers.d/runner

## Node layer
FROM base AS tool-node

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
        /home/runner/.npm-global \
        /home/runner/.npm \
    && chown -R runner:runner \
        /home/runner/.npm-global \
        /home/runner/.npm

## Set Node env vars
ENV NPM_CONFIG_PREFIX=/home/runner/.npm-global
ENV PATH=/home/runner/.npm-global/bin:$PATH

RUN corepack enable \
    && corepack install --global pnpm@11

## Go layer
FROM tool-node AS tool-go

ARG GO_VERSION
ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) GO_ARCH="amd64" ;; \
        arm64) GO_ARCH="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" \
        -o /tmp/go.tar.gz; \
    rm -rf /usr/local/go; \
    tar -xzf /tmp/go.tar.gz -C /usr/local; \
    rm -f /tmp/go.tar.gz; \
    /usr/local/go/bin/go version

## Set Go env vars
ENV PATH=/usr/local/go/bin:/home/runner/.npm-global/bin:$PATH
ENV GOTOOLCHAIN=local

## Runtime layer
FROM tool-go AS run

RUN git config --system --add safe.directory '*'

RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN mkdir -p \
        /opt/hostedtoolcache/go \
        /opt/hostedtoolcache/node \
        /opt/hostedtoolcache/Python \
        /home/runner/.cache \
    && chown -R runner:runner \
        /opt/hostedtoolcache \
        /home/runner/.cache

WORKDIR /workspace

USER runner

## Verify installed tooling
RUN node --version \
    && npm --version \
    && pnpm --version \
    && go version \
    && which node \
    && which npm \
    && which pnpm \
    && which go

CMD ["/bin/bash"]
