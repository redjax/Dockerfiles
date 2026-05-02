ARG TRUFFLEHOG_TAG=3.95.2

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM trufflesecurity/trufflehog:${TRUFFLEHOG_TAG}

## Import args from outer layer
ARG TRUFFLEHOG_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

WORKDIR /repo

ENTRYPOINT ["trufflehog"]

LABEL org.opencontainers.image.title="trufflhog" \
      org.opencontainers.image.base.name="trufflesecurity/trufflehog:${TRUFFLEHOG_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Image derived from the official Trufflehog container."

CMD ["--help"]
