# renovate: datasource=npm depName=renovate versioning=node
ARG RENOVATE_VERSION=44.29.4

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

## Use forgejo-runner-base as base layer
FROM ghcr.io/redjax/dockerfiles/forgejo-runner-base:latest

## Import args from outer layer
ARG RENOVATE_VERSION
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

## Switch to container root user for setup
USER root

## Install renovate with npm & print versions
RUN mkdir -p /home/runner/.npm-global \
  && npm install -g "renovate@${RENOVATE_VERSION}" \
  && chown -R runner:runner /home/runner/.npm-global

## Print Node version
RUN echo "Node version:" \
  && command -v node \
  && node --version

## Print NPM version
RUN command -v npm \
  && npm --version

## Print Go version
RUN echo "Go version:" \
    && command -v go \
    && go version

## Print Renovate version
RUN echo "Renovate version:" \
  && command -v renovate \
  && renovate --version

WORKDIR /workspace

USER runner

LABEL org.opencontainers.image.title="forgejo-renovate" \
      org.opencontainers.image.base.name="ghcr.io/redjax/dockerfiles/forgejo-runner-base:latest" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/automation/renovate/README.md" \
      org.opencontainers.image.description="Forgejo Actions runner image with Renovate preinstalled."

CMD ["/bin/bash"]
