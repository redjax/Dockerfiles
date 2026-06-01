ARG KICS_TAG=2.1.20
ARG ALPINE_TAG=3.22.4

FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache bash ca-certificates curl tar coreutils unzip

ARG KICS_VERSION
ENV KICS_VERSION=${KICS_VERSION}

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

