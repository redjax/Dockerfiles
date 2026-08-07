# renovate: datasource=npm depName=renovate versioning=node
ARG RENOVATE_VERSION=44.14.8

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM ghcr.io/redjax/dockerfiles/forgejo-runner-base:latest

## Import args from outer layer
ARG RENOVATE_VERSION
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

USER root

ENV NPM_CONFIG_PREFIX=/home/runner/.npm-global
ENV PATH=/home/runner/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN mkdir -p /home/runner/.npm-global \
    && npm install -g renovate@${RENOVATE_VERSION} \
    && renovate --version \
    && chown -R runner:runner /home/runner/.npm-global

WORKDIR /workspace

USER runner

RUN node --version \
    && npm --version \
    && renovate --version

LABEL org.opencontainers.image.title="forgejo-renovate" \
      org.opencontainers.image.base.name="ghcr.io/redjax/dockerfiles/forgejo-runner-base:latest" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/automation/renovate/README.md" \
      org.opencontainers.image.description="Forgejo Actions runner image with Renovate preinstalled."

CMD ["/bin/bash"]
