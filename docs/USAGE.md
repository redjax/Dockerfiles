# Usage <!-- omit in toc -->

> [!WARNING]
> This document describes the desired state of this repository. Until this message is removed, it is possible/likely that the automations described are not fully functional yet.

Container image updates for images in this repository are automated by Renovate and CI/CD pipelines to keep the published images in sync with their upstream versions. An `image.yml` manifest alongside each `Dockerfile` defines the upstream container to watch and the versioned build arguments to keep in sync. Renovate updates those manifests and Dockerfile `ARG` defaults when new versions are available, and the build pipeline rebuilds and publishes the containers.

## Table of Contents <!-- omit in toc -->

- [Repository layout](#repository-layout)
  - [Manifest fields](#manifest-fields)
  - [Versioned values](#versioned-values)
- [Building images](#building-images)
  - [Build script](#build-script)
  - [Build arguments](#build-arguments)
  - [Renovate configuration](#renovate-configuration)
  - [Automated bumps vs. manual changes](#automated-bumps-vs-manual-changes)
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
context: dockerfiles/base/alpine
dockerfile: dockerfiles/base/alpine/Dockerfile
registry_path: ghcr.io/redjax/dockerfiles/alpine-base

components:
  alpine:
    type: dockerhub
    name: alpine
    track: 3.22
    version: 3.22.4
    arg: ALPINE_TAG

upstream:
  registry: docker
  name: alpine
  track: 3.22
  version: 3.22.4
```

### Manifest fields

- `name`: The published container name.
- `category`: The image type, such as `base`, `tool`, or `ci`.
- `description`: A short summary of the container.
- `publish`: When `true`, the publish pipeline builds and releases the image if there are changes.
- `context`: The build context path from the repository root.
- `dockerfile`: The Dockerfile path from the repository root.
- `registry_path`: The image registry path used when publishing.
- `components`: Defines all versioned dependencies used in the image (both base images and installed tools). Each component defines:
  - `type`: Source of version data (dockerhub, github_release, etc.)
  - `name` or `repo`: Identifier for lookup
  - `track`: Version track to follow
  - `version`: Current resolved version
  - `arg`: (optional) Dockerfile ARG that should be updated when version changes
- `upstream`: Metadata for the image the container is based on, used by automation to detect new versions. Each upstream defines:
  - `registry`: Registry type (`docker`, `ghcr`, `gitlab`, etc.)
  - `name`: Image name
  - `track`: Version track to follow
  - `version`: Currently pinned version
- `version_args`: Build arguments whose default values should stay aligned with the manifest and Dockerfile.
- `args`: Additional build arguments passed into the container at build time.

### Versioned values

The `upstream.version` and `version_args` entries are typically the values updated by Renovate. The `upstream.track` field defines the version pattern to watch, while `upstream.version` pins the exact version currently in use.

## Building images

### Build script

The [`build-image.sh`](../scripts/build/build-image.sh) script is a generic helper for building container images from this repository. It can be used for local builds or from a pipeline.

Example: build the [base Alpine container](../dockerfiles/base/alpine/Dockerfile)

```shell
./scripts/build/build-image.sh \
  --context dockerfiles/base/alpine \
  --dockerfile dockerfiles/base/alpine/Dockerfile \
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

### Renovate configuration

Each versioned `ARG` in a Dockerfile that you want Renovate to manage should be annotated with a comment describing its datasource, dependency name, and versioning rules. For example:

```dockerfile
## https://hub.docker.com/_/alpine
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.23.4

## https://github.com/terraform-linters/tflint/releases
# renovate: datasource=github-releases depName=terraform-linters/tflint extractVersion=^v(?<version>.*)$
ARG TFLINT_VERSION=0.62.0
```

The corresponding `image.yml` ties those ARGs to upstream metadata:

```yaml
upstream:
  registry: docker
  name: alpine
  track: 3.23
  version: 3.23.5

version_args:
  ALPINE_TAG: 3.23.4
  TFLINT_VERSION: v0.62.0

args:
  ALPINE_TAG: 3.23.4
  TFLINT_VERSION: v0.62.0
```

Renovate’s Docker and regex managers keep `upstream.version`, `version_args`, `args`, and the Dockerfile `ARG` defaults in sync.

### Automated bumps vs. manual changes

Renovate runs automatically on a schedule defined in [`.github/workflows/renovate.yml`](../.github/workflows/renovate.yml). It discovers new versions for:

- Base images via the `dockerfile` manager.
- Tool versions via `regexManagers` and `components` in `image.yml`.

It opens PRs that update:

- `upstream.version` and `version_args` in `image.yml`.
- Annotated `ARG` defaults in Dockerfiles.

With `automerge` enabled, Renovate merges those PRs automatically once checks pass. The `build-publish` workflow rebuilds and publishes containers for any changed `image.yml`/`Dockerfile` definitions.

Manual changes to manifests or Dockerfiles (for example, adding new components or adjusting tracks) are still possible; Renovate will pick up those changes as the new baseline for future updates.

## Generic manifest example

```yaml
---
name: terraform-tools
category: tooling
description: Terraform CLI image with tflint and tfsec installed.
publish: true
context: dockerfiles/iac/terraform
dockerfile: dockerfiles/iac/terraform/Dockerfile
registry_path: ghcr.io/redjax/dockerfiles/terraform-tools

components:
  terraform:
    type: dockerhub
    name: hashicorp/terraform
    track: 1.14
    version: 1.14.9
    arg: TERRAFORM_TAG

  tflint:
    type: github_release
    repo: terraform-linters/tflint
    track: v0.62
    version: 0.62.0
    arg: TFLINT_VERSION

  tfsec:
    type: github_release
    repo: aquasecurity/tfsec
    track: v1.28
    version: 1.28.14
    arg: TFSEC_VERSION

upstream:
  registry: docker
  name: hashicorp/terraform
  track: 1.14
  version: 1.14.9
```

This keeps the image definition, build inputs, and pinned version values in one place. Renovate reads this manifest and the associated Dockerfile comments to keep those fields updated when new releases are available, while the Dockerfile remains focused on build behavior.
