# syntax=docker/dockerfile:1

ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"

FROM texlive/texlive:latest-small@sha256:787564f7d055c2a66e3ca8d1bd5c617373dbc8b5d280f22d62b07b46bb3a5c41

ARG IMAGE_VERSION
ARG IMAGE_CREATED
ARG IMAGE_SOURCE

ARG TLMGR_REPO_URL=https://tug.ctan.org/systems/texlive/tlnet

RUN tlmgr option repository "${TLMGR_REPO_URL}" \
    && tlmgr update --self \
    && tlmgr install latexmk

WORKDIR /workspace

LABEL org.opencontainers.image.title="latex-base" \
      org.opencontainers.image.base.name="texlive/texlive:latest-small" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="https://github.com/redjax/Dockerfiles/blob/main/dockerfiles/documents/latex/README.md" \
      org.opencontainers.image.description="Reusable TeX Live build environment with latexmk."

ENTRYPOINT []

CMD ["/bin/bash"]
