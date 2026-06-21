# Base: Python uv

Container image with the [Astral uv](https://docs.astral.sh/uv) Python package manager installed on a minimal Debian base.

This image is intended as a general-purpose Python runtime base, providing:

- `uv` (Python dependency manager and project tool)
- `python` (via system or uv-managed environments)
- Common build and development tooling:
  - `curl`
  - `wget`
  - `git`
  - `build-essential`
  - `pkg-config`
  - `libssl-dev`
  - `zlib1g-dev`
- Standard working directory: `/work`

This image is designed to be used as a foundation for Python application images, CI pipelines, and build environments where reproducible dependency management via `uv` is required.

## Usage

This image is not application-specific. It is intended to be used as a base for downstream images.

Example Dockerfile:

```dockerfile
FROM ghcr.io/redjax/dockerfiles/uv-base:latest

WORKDIR /work

COPY pyproject.toml uv.lock ./

RUN uv sync

```

Example runtime command:

```shell
docker run --rm -it \
  -v $(pwd):/work \
  ghcr.io/redjax/dockerfiles/uv-base:latest \
  uv run python app.py
```

## Build

```shell
docker build \
    --tag uv-base:latest \
    --build-arg DEBIAN_TAG="12.13" \
    --build-arg UV_BASE="0.9.18" \
    .
```

## Design Notes

- Uses the official `ghcr.io/astral-sh/uv` image as the source of the uv binary
- Installs minimal system tooling required for Python package builds
- Keeps the image stateless and reusable
- Does not include application code or virtual environments
- Standardizes `/work` as the working directory for all derived images
