## https://github.com/Checkmarx/kics/releases
# renovate: datasource=github-releases depName=Checkmarx/kics extractVersion=^v?(?<version>.*)$
ARG KICS_TAG=2.1.21
## https://hub.docker.com/_/alpine
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1

## Metadata defaults
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM alpine:${ALPINE_TAG}

ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

RUN apk add --no-cache bash ca-certificates curl tar coreutils unzip

## Import KICS_TAG from the outer stage and expose KICS_VERSION
ARG KICS_TAG
ENV KICS_VERSION="${KICS_TAG}"

COPY install-kics.sh /tmp/install-kics.sh
RUN chmod +x /tmp/install-kics.sh \
  && /tmp/install-kics.sh \
  && rm -f /tmp/install-kics.sh

## Metadata
LABEL org.opencontainers.image.title="kics" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/security/kics/README.md" \
      org.opencontainers.image.description="Image derived from the official KICS container."

ENTRYPOINT ["kics"]
CMD ["version"]
