## https://hub.docker.com/r/renovate/renovate/
# renovate: datasource=docker depName=renovate/renovate versioning=docker
ARG RENOVATE_TAG=44.4.5-full
## https://hub.docker.com/_/debian
# renovate: datasource=docker depName=debian versioning=docker
ARG DEBIAN_TAG=13.6-slim

FROM renovate/renovate:${RENOVATE_TAG} AS base

FROM debian:${DEBIAN_TAG} AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    unzip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=base /usr/local/sbin/renovate /usr/local/bin/renovate

WORKDIR /work
ENTRYPOINT ["renovate"]
CMD ["--help"]
