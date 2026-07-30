## https://hub.docker.com/_/alpine
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1

## https://github.com/dependabot/cli/releases
# renovate: datasource=github-releases depName=dependabot/cli extractVersion=^v?(?<version>.*)$
ARG DEPENDABOT_VERSION=v1.91.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM alpine:3.24

## Import args from outer layer
ARG DEPENDABOT_VERSION
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

USER root

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    docker \
    docker-cli-compose \
    git \
    openssh-client \
    tar

ARG DEPENDABOT_VERSION

RUN curl -fsSL \
      "https://github.com/dependabot/cli/releases/download/${DEPENDABOT_VERSION}/dependabot-${DEPENDABOT_VERSION}-linux-amd64.tar.gz" \
      -o /tmp/dependabot.tar.gz \
    && tar -xzf /tmp/dependabot.tar.gz -C /usr/local/bin dependabot \
    && rm -f /tmp/dependabot.tar.gz \
    && chmod +x /usr/local/bin/dependabot

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="dependabot-cli" \
      org.opencontainers.image.base.name="alpine:3.20" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/tooling/dependabot/README.md" \
      org.opencontainers.image.description="Image with Dependabot CLI for automating dependency updates."

ENTRYPOINT ["/usr/local/bin/dependabot"]
