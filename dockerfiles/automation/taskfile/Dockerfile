## https://hub.docker.com/_/alpine
ARG ALPINE_TAG=3.22.4
## https://github.com/taskfile/task/releases
ARG TASKFILE_VERSION=v3.50.0

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

RUN curl -fsSL \
      "https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz" \
      -o /tmp/taskfile.tar.gz \
    && mkdir /tmp/taskfile \
    && tar -xzvf /tmp/taskfile.tar.gz -C /tmp/taskfile \
    && rm -rf /tmp/taskfile.tar.gz \
    && chmod +x /tmp/taskfile/task \
    && mv /tmp/taskfile/task /usr/local/bin/task \
    && rm -rf /tmp/taskfile

## Metadata
LABEL org.opencontainers.image.title="taskfile" \
      org.opencontainers.image.base.name="taskfile:${ALPINE_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Alpine image with Taskfile installed for build automation."

## Set entrypoint to task binary so docker run commands execute taskfile
ENTRYPOINT ["/usr/local/bin/task"]

## Print help menu if no command is passed
CMD ["-h"]
