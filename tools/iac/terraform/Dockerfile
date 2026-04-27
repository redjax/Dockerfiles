## https://hub.docker.com/r/hashicorp/terraform
ARG TERRAFORM_TAG=1.14.9
## https://github.com/terraform-linters/tflint/releases
ARG TFLINT_VERSION=0.62.0
## https://github.com/aquasecurity/tfsec/releases
ARG TFSEC_VERSION=1.28.14

FROM hashicorp/terraform:${TERRAFORM_TAG}

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

ENTRYPOINT ["/bin/sh"]
