ARG GITLEAKS_TAG=v8.30.1

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM ghcr.io/gitleaks/gitleaks:${GITLEAKS_TAG}

## Import args from outer layer
ARG GITLEAKS_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

WORKDIR /repo

ENTRYPOINT ["gitleaks"]

## Metadata
LABEL org.opencontainers.image.title="gitleaks" \
      org.opencontainers.image.base.name="ghcr.io/gitleaks/gitleaks:${GITLEAKS_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Image derived from official Gitleaks image."

CMD ["version"]
