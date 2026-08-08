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

FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION
ARG TARGETARCH

ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    ## Shell / system basics
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
    \
    ## JSON/YAML/data tooling
    jq \
    yq \
    \
    ## Archives
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zip \
    unzip \
    p7zip-full \
    \
    ## Build tooling
    build-essential \
    make \
    pkg-config \
    \
    ## Python
    python3 \
    python3-pip \
    python3-venv \
    \
    ## Misc utilities
    rsync \
    file \
    patch \
    diffutils \
    gettext \
    gnupg \
    openssl \
    \
    ## Docker client
    docker.io \
    && rm -rf /var/lib/apt/lists/*

## Create Forgejo runner user
RUN useradd \
    --create-home \
    --shell /bin/bash \
    --groups sudo \
    runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

## Node.js 24 + pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

## Create user-writeable Node cache dir
RUN mkdir -p \
    /home/runner/.npm-global \
    /home/runner/.npm \
    && chown -R runner:runner \
    /home/runner/.npm-global \
    /home/runner/.npm

ENV NPM_CONFIG_PREFIX=/home/runner/.npm-global
ENV PATH=/usr/local/go/bin:/home/runner/.npm-global/bin:$PATH

RUN corepack enable \
    && corepack install --global pnpm@11

## Install Go

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

ENV PATH=/usr/local/go/bin:/home/runner/.npm-global/bin:$PATH
ENV GOTOOLCHAIN=auto

## Git configuration
RUN git config --system --add safe.directory '*'

## Enable UTF-8 locale
RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

## Create Actions tool cache dir
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
