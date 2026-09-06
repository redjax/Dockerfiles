## https://hub.docker.com/_/alpine
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1
## https://github.com/taskfile/task/releases
# renovate: datasource=github-releases depName=go-task/task extractVersion=^v(?<version>.*)$
ARG TASKFILE_VERSION=3.53.1

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM alpine:${ALPINE_TAG} AS base

RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    git \
    openssh-client \
    jq

RUN update-ca-certificates

FROM base AS taskfile

## Import args from outer layer
ARG ALPINE_TAG
ARG TASKFILE_VERSION

ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

WORKDIR /work

RUN curl --fail --show-error --location \
      "https://github.com/go-task/task/releases/download/v${TASKFILE_VERSION}/task_linux_amd64.tar.gz" \
      --output /tmp/taskfile.tar.gz \
    && mkdir -p /tmp/taskfile \
    && tar --extract \
      --gzip \
      --file /tmp/taskfile.tar.gz \
      --directory /tmp/taskfile \
    && install \
      --mode=0755 \
      /tmp/taskfile/task \
      /usr/local/bin/task \
    && rm -rf \
      /tmp/taskfile.tar.gz \
      /tmp/taskfile

## Metadata
LABEL org.opencontainers.image.title="taskfile" \
      org.opencontainers.image.base.name="taskfile:${ALPINE_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/automation/taskfile/README.md" \
      org.opencontainers.image.description="Alpine image with Taskfile installed for build automation."

## Set entrypoint to task binary so docker run commands execute taskfile
ENTRYPOINT ["/usr/local/bin/task"]

## Print help menu if no command is passed
CMD ["-h"]
