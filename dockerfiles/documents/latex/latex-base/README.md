# Documents: LaTeX Base

Reusable base image for building LaTeX documents. Includes [TeX Live](https://tug.org/texlive/) environment.

The image does not contain project sources or impose a document build command. Individual projects can inherit from this container to skip the Tex Live install step, and install their own packages/write their own build commands.

## Build

```shell
docker build \
    --tag latex-base:dev \
    dockerfiles/documents/latex
```

## Compile a document

Run from a project containing `main.tex`:

```shell
docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --mount "type=bind,source=$(pwd),target=/workspace" \
    latex-base:dev \
    latexmk \
      -pdf \
      -interaction=nonstopmode \
      -halt-on-error \
      -outdir=build \
      main.tex
```

## Extend the image

Install project-specific packages in the consuming repository's Dockerfile:

```dockerfile
FROM ghcr.io/redjax/dockerfiles/latex-base:latest

RUN tlmgr update --self \
    && tlmgr install fontawesome5 helvetic
```

Use a published version tag or digest instead of `latest` when pinning a project's build environment.
