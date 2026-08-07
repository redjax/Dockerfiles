###############################################
# Forgejo Actions universal runner base image #
#                                             #
# Includes tooling most pipelines would need, #
# like node/npm, curl/wget, build tooling,    #
# ssh, docker.io client, and more.            #
###############################################

ARG UBUNTU_VERSION=26.10

FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

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
ENV PATH=/home/runner/.npm-global/bin:$PATH

RUN corepack enable \
    && corepack install --global pnpm@11

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

## Verify user can run node
RUN node --version \
    && npm --version \
    && pnpm --version \
    && which node \
    && which npm \
    && which pnpm

CMD ["/bin/bash"]
