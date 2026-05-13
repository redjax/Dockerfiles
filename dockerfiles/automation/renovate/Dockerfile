## https://hub.docker.com/r/renovate/renovate/
ARG RENOVATE_TAG=43.176.4-full

FROM renovate/renovate:${RENOVATE_TAG}

RUN apt-get update && apt-get install -y \
    git \
    jq \
    bash \
 && rm -rf /var/lib/apt/lists/*