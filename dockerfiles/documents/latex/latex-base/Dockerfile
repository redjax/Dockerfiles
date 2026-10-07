# syntax=docker/dockerfile:1

# renovate: datasource=docker depName=texlive/texlive
ARG TEXLIVE_IMG_TAG=latest-small

ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM texlive/texlive:${TEXLIVE_IMG_TAG}

ARG TEXLIVE_IMG_TAG
ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

ARG TLMGR_REPO_URL=https://tug.ctan.org/systems/texlive/tlnet

RUN tlmgr option repository "${TLMGR_REPO_URL}" \
    && tlmgr update --self \
    && tlmgr install latexmk

WORKDIR /workspace

LABEL org.opencontainers.image.title="latex-base" \
      org.opencontainers.image.base.name="texlive/texlive:${TEXLIVE_IMG_TAG}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/documents/latex/README.md" \
      org.opencontainers.image.description="Reusable TeX Live build environment with latexmk."

ENTRYPOINT []

CMD ["/bin/bash"]
