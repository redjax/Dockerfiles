#########################################################
# Example Debian container derived from upstream image. #
#########################################################

## If the container pulls from an upstream image, pass the desired version
#  as a build arg. The arg name must be different from other containers,
#  e.g. 2 containers should not have the same `SOME_TAG` variable.
ARG UNIQUE_NAME_TAG=0.0.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

## Use the tag defined above
FROM debian:${DEBIAN_TAG}

## Import args from outer layer
ARG UNIQUE_NAME_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

## Disable interactive apt prompts
ENV DEBIAN_FRONTEND=noninteractive

## Install some packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

## Set the working directory in the container
WORKDIR /work

## Container metadata. Override in scripts/docker build commands
LABEL org.opencontainers.image.title="debian-base" \
      org.opencontainers.image.base.name="debian:${DEBIAN_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Minimal Debian base image with additional tooling installed."

## Run command on startup
CMD ["/bin/bash"]
