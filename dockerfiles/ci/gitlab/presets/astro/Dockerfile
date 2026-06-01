#########################################################
# Opinionated GitLab CI image for Astro site pipelines. #
#########################################################

## https://hub.docker.com/layers/library/docker/latest/
ARG DOCKER_IMG_VER=29.5.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM docker:${DOCKER_IMG_VER}-cli

## Import args from outer layer
ARG DOCKER_IMG_VER
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

RUN apk add --no-cache \
    bash \
    coreutils \
    curl \
    git \
    nodejs \
    npm \
    python3 \
    py3-pip \
    pipx

ENV PATH="/root/.local/bin:$PATH"

RUN pipx ensurepath \
    && pipx install bump-my-version

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="gitlab-astro" \
      org.opencontainers.image.base.name="docker:${DOCKER_IMG_VER}-cli" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/ci/gitlab/presets/astro/README.md" \
      org.opencontainers.image.description="Opinionated GitLab CI image for Astro pipelines with Docker, Node, and Python tooling."

CMD ["/bin/sh"]
