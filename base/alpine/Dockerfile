## https://hub.docker.com/_/alpine
ARG ALPINE_TAG=3.22.4

FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    git \
    openssh-client \
    jq

RUN update-ca-certificates

WORKDIR /work

CMD ["/bin/ash"]

