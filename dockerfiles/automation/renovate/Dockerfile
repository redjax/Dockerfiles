## https://hub.docker.com/r/renovate/renovate/
ARG RENOVATE_TAG=43.176.4-full
## https://hub.docker.com/_/debian
ARG DEBIAN_TAG=12.13-slim

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
