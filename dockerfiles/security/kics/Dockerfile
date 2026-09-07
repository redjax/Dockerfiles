## https://github.com/Checkmarx/kics/releases
# renovate: datasource=docker depName=checkmarx/kics extractVersion=^v?(?<version>.*)$
ARG KICS_TAG=2.1.20
## https://hub.docker.com/_/alpine
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1

## Metadata defaults
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM checkmarx/kics:v${KICS_TAG} AS kics
FROM alpine:${ALPINE_TAG}

ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

RUN apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  tar \
  coreutils \
  unzip

## Copy KICS and its runtime assets from the official image
COPY --from=kics /app/bin/kics /usr/local/bin/kics
COPY --from=kics /app/bin/assets /usr/local/share/kics/assets

## KICS uses its bundled query and supporting asset directories.
ENV KICS_QUERIES_PATH="/usr/local/share/kics/assets/queries"

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="kics" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/security/kics/README.md" \
      org.opencontainers.image.description="Image derived from the official KICS container."

ENTRYPOINT ["kics"]
CMD ["version"]
