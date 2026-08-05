###############################################
# Forgejo Actions universal runner base image #
#                                             #
# Includes tooling most pipelines would need, #
# like node/npm, curl/wget, build tooling,    #
# ssh, docker.io client, and more.            #
###############################################

ARG UBUNTU_VERSION=24.04

FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    \
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
    ## Node
    nodejs \
    npm \
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

## Enable UTF-8 locale
RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

## Create Forgejo runner user
RUN useradd \
    --create-home \
    --shell /bin/bash \
    --groups sudo \
    runner \
 && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

## Create Actions tool cache dir
RUN mkdir -p /opt/hostedtoolcache \
    /opt/hostedtoolcache/go \
 && chown -R runner:runner /opt/hostedtoolcache

WORKDIR /workspace

USER runner

CMD ["/bin/bash"]
