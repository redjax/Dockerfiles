## https://hub.docker.com/r/hashicorp/terraform
ARG TERRAFORM_TAG=1.14.9
## https://github.com/terraform-linters/tflint/releases
ARG TFLINT_VERSION=0.62.0
## https://github.com/aquasecurity/tfsec/releases
ARG TFSEC_VERSION=1.28.14

## Metadata defaults. Override in scripts/pipelines
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM hashicorp/terraform:${TERRAFORM_TAG}

## Import args from outer layer
ARG TERRAFORM_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

USER root

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    unzip

ARG TFLINT_VERSION

RUN curl -fsSL \
      "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" \
      -o /tmp/tflint.zip \
    && unzip -q /tmp/tflint.zip -d /usr/local/bin \
    && rm -f /tmp/tflint.zip \
    && chmod +x /usr/local/bin/tflint

ARG TFSEC_VERSION
RUN curl -fsSL \
      "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" \
      -o /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

WORKDIR /work

## Metadata
LABEL org.opencontainers.image.title="terraform-tools" \
      org.opencontainers.image.base.name="hashicorp/terraform:${TERRAFORM_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.description="Image with Terraform and development tools like tflint and tfsec."

ENTRYPOINT ["/bin/sh"]
