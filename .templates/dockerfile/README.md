# Dockerfile Templates

Dockerfiles in this repository follow a general pattern of build args, layer construction, & downloading releases from Github/other URLs. The general structure (which may change signficantly depending on the configuration of an image) is:

```dockerfile
## If the container pulls from an upstream image, pass the desired version
#  as a build arg. The arg name must be different from other containers,
#  e.g. 2 containers should not have the same `SOME_TAG` variable.
ARG UNIQUE_NAME_TAG=0.0.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

## Use the tag defined above
FROM upstream-img:${DEBIAN_TAG}

## Import args from outer layer
ARG UNIQUE_NAME_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

## Disable interactive apt prompts.
#  Only used for Debian/Ubuntu family images.
ENV DEBIAN_FRONTEND=noninteractive

## Install some packages (assumes debian/apt,
#  use the appropriate commands for your image's package manager).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

## Set the working directory in the container
WORKDIR /work

## Container metadata. Override in scripts/docker build commands
LABEL org.opencontainers.image.title="img-name" \
      org.opencontainers.image.base.name="img-name:${UNIQUE_NAME_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="A short description of the container."

## An optional entrypoint. One use for this is a tool running in a container.
#  You can set the entrypoint to the tool's path and pass args from the docker run command
# ENTRYPOINT ["/some/bin/path"]

## Run command on startup
CMD ["/bin/bash"]

```
