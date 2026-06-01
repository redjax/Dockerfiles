#########################################################
# Lightweight container to provide Gitlab CI pipelines  #
# with shell utilities it can use for jobs.             #
#########################################################

## Releases: https://hub.docker.com/layers/library/docker/latest/
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
    git \
    curl

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="gitlab-docker-base" \
      org.opencontainers.image.base.name="docker:${DOCKER_IMG_VER}-cli" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="GitLab CI base image with Docker CLI and core shell tooling."

CMD ["/bin/sh"]