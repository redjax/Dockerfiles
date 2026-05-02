ARG TRIVY_TAG=0.70.0

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM aquasec/trivy:${TRIVY_TAG}

## Import args from outer layer
ARG TRIVY_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

WORKDIR /scan

ENTRYPOINT ["trivy"]

## Metadata
LABEL org.opencontainers.image.title="trivy" \
      org.opencontainers.image.base.name="aquasec/trivy:${TRIVY_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Image derived from the official Trivy container."

CMD ["--help"]
