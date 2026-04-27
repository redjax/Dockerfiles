# Usage <!-- omit in toc -->

> [!WARNING]
> This document describes the desired state of this repository. Until this message is removed, it is possible/likely that the automations described are not fully functional yet.

Container image updates for images in this repository are automated by CI/CD pipelines to keep the published images in-sync with their upstream versions. An `image.yml` manifest alongside each `Dockerfile` defines the upstream container to watch, and rebuilds the container when there is an newer version.

## Table of Contents <!-- omit in toc -->

- [Repository layout](#repository-layout)
  - [Manifest fields](#manifest-fields)
  - [Versioned values](#versioned-values)
- [Building images](#building-images)
  - [Build script](#build-script)
  - [Build arguments](#build-arguments)
- [Updating version pins](#updating-version-pins)
  - [Bump script](#bump-script)
  - [Version argument rules](#version-argument-rules)
- [Generic manifest example](#generic-manifest-example)

## Repository layout

This repository uses an `image.yml` manifest alongside each `Dockerfile` image definition to describe where the Dockerfile lives and which versioned build arguments should be kept in sync. The manifest acts as the source of truth for image-specific metadata, while the Dockerfile uses `ARG` defaults for the pinned versions used at build time.

A typical manifest looks like:

```yaml
---
name: container-name
category: base
description: A short description for the container.
publish: true
context: base/alpine
dockerfile: base/alpine/Dockerfile
registry_path: ghcr.io/redjax/dockerfiles/alpine-base
upstream:
  registry: docker
  name: alpine
  track: 3.22
  version: 3.22.4
version_args:
  ALPINE_TAG: 3.22.4
args:
  ALPINE_TAG: 3.22.4

```

### Manifest fields

- `name`: The published container name.
- `category`: The image type, such as `base`, `tool`, or `ci`.
- `description`: A short summary of the container.
- `publish`: When `true`, the publish pipeline builds and releases the image if there are changes.
- `context`: The build context path from the repository root.
- `dockerfile`: The Dockerfile path from the repository root.
- `registry_path`: The image registry path used when publishing.
- `upstream`: Metadata for the image the container is based on, used by bump workflows to detect new versions.
- `version_args`: Build arguments whose default values should stay aligned with the manifest and Dockerfile.
- `args`: Additional build arguments passed into the container at build time.

### Versioned values

The `upstream.version` and `version_args` entries are typically the values updated by automation. The `upstream.track` field defines the version pattern to watch, while `upstream.version` pins the exact version currently in use.

## Building images

### Build script

The [`build-image.sh`](../scripts/build/build-image.sh) script is a generic helper for building container images from this repository. It can be used for local builds or from a pipeline.

Example: build the [base Alpine container](../base/alpine/Dockerfile)

```shell
./scripts/build/build-image.sh \
  --context base/alpine \
  --dockerfile base/alpine/Dockerfile \
  --name alpine-base \
  --tag 3.22.4 \
  --build-arg ALPINE_TAG=3.22
```

### Build arguments

Docker build arguments are provided with `--build-arg`. These values exist only during the build unless they are copied into `ENV` or otherwise persisted by the Dockerfile.

If a Dockerfile declares:

```dockerfile
ARG ALPINE_TAG=3.22
```

then the build uses `3.22` unless a different value is passed at build time.

## Updating version pins

### Bump script

Each image directory can include an `image.yml` manifest that defines the Dockerfile path and the versioned build args that belong to that image. The bump script reads that manifest and updates matching `ARG` defaults in the referenced Dockerfile so the pinned values stay in sync with the repository metadata.

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

The `version_args` section should contain only build arguments that are declared in the Dockerfile with `ARG`. The script updates only matching `ARG NAME=value` lines, which keeps the Dockerfile defaults aligned with the manifest without changing unrelated build settings.

Example `Dockerfile` fragment:

```dockerfile
ARG ALPINE_TAG=3.22
ARG BUSYBOX_TAG=1.37
```

When the manifest changes, rerun the bump script to update the Dockerfile defaults before building or committing the image definition.

## Generic manifest example

For a simple image definition, the manifest can be as small as this:

```yaml
---
name: alpine-base
category: base
description: Alpine-based utility image
publish: true
context: base/alpine
dockerfile: base/alpine/Dockerfile
registry_path: ghcr.io/redjax/dockerfiles/alpine-base
upstream:
  registry: docker
  name: alpine
  track: 3.22
  version: 3.22.4
version_args:
  ALPINE_TAG: 3.22.4
args:
  ALPINE_TAG: 3.22.4
```

This keeps the image definition, build inputs, and pinned version values in one place, while the Dockerfile remains focused on build behavior.
