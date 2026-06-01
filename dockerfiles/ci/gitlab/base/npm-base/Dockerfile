#########################################################
# Focused GitLab CI base image for Node/NPM workflows.  #
#########################################################

## https://hub.docker.com/_/alpine
ARG ALPINE_TAG=3.23.4

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM alpine:${ALPINE_TAG}

## Import args from outer layer
ARG ALPINE_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

RUN apk add --no-cache \
    bash \
    curl \
    git \
    nodejs \
    npm

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="gitlab-npm-base" \
      org.opencontainers.image.base.name="alpine:${ALPINE_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="GitLab CI base image for Node.js and npm jobs."

CMD ["/bin/ash"]
