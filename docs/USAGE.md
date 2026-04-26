# Usage

## Repository layout

This repository uses an `image.yml` manifest alongside each `Dockerfile` image definition to describe where the Dockerfile lives and which versioned build arguments should be kept in sync. The manifest acts as the source of truth for image-specific metadata, while the Dockerfile uses ARG defaults for the pinned versions used at build time.

A typical manifest looks like:

```yaml
---
name: container-name  # The name for the container when it's published
category: base  # The type of Dockerfile, i.e. base, tool, ci
description: A short description for the container.  # Describes the purpose/structure of the container
publish: true  # When `true`, the publish pipeline will build and release the container if there are changes
context: base/alpine  # Path from the repository root to the working directory of the container
dockerfile: base/alpine/Dockerfile  # Path from the repository root to the Dockerfile
registry_path: ghcr.io/redjax/Dockerfiles/alpine-base  # Registry URL where the image will be pulished if publish: true
upstream:  # Most containers in this repo inherit from an upstream container. This section helps the bump script detect new versions
  registry: docker  # Container registry to query, i.e. docker, ghcr, gitlab, acr
  name: alpine  # The base name of the upstream container
  track: 3.22  # The version/tag pattern to watch. This 'prefix' does not need to be the whole version, just the pattern to match
  version: 3.22.4  # Pin a specific version. The bump script updates this value
version_args:
  ALPINE_TAG: 3.22.4  # Tell the bump script which container arg(s) define versions for the Dockerfile. The bump script updates this value
args:
  ALPINE_TAG: 3.22.4  # Args to pass into the container at build time. The bump script updates this value

```

## Building images

### Build script

The [`build-image.sh`](../scripts/build/build-image.sh) is a generic script for building container images from this repository. It can be called for local builds, or from a pipeline.

Example: build the [base Alpine container](../base/alpine/Dockerfile)

```shell
./scripts/build/build-image.sh \
  --context base/alpine \
  --dockerfile base/alpine/Dockerfile \
  --name alpine-base \
  --tag 3.22.4 \
  --build-arg ALPINE_TAG=3.22
```

## Updating version pins

### Bump script

Each image directory can include an `image.yml` manifest that defines the `Dockerfile` path and the versioned build args that belong to that image. The bump script reads that manifest and updates matching `ARG` defaults in the referenced Dockerfile so the pinned values stay in sync with the repository metadata.

Example:

```shell
./scripts/update/bump-dockerfile-arg.sh \
  --file base/alpine/image.yml
```

> [!TIP]
> Use `--dry-run` to preview changes without modifying files:
>
> ```shell
> ./scripts/update/bump-dockerfile-arg.sh \
>   --file base/alpine/image.yml \
>   --dry-run
> ```

### Version argument rules

The version_args section should contain only build arguments that are declared in the Dockerfile with ARG. The script updates only matching `ARG NAME=value` lines, which keeps the Dockerfile defaults aligned with the manifest without changing unrelated build settings.

Example `Dockerfile` fragment:

```dockerfile
ARG ALPINE_TAG=3.22
ARG BUSYBOX_TAG=1.37
```

When the manifest changes, rerun the bump script to update the Dockerfile defaults before building or committing the image definition.
