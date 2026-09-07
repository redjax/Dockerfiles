# Usage <!-- omit in toc -->

Container image updates in this repository are automated with Renovate and GitHub Actions. Renovate updates dependency versions declared in Dockerfiles, while the build pipeline detects changed image directories, validates pull requests, and publishes changed images to GHCR after they reach `main`.

Each image has a `metadata.yml` file containing static image metadata. Dependency versions are not stored in metadata files.

## Table of Contents <!-- omit in toc -->

- [Repository layout](#repository-layout)
  - [Image metadata](#image-metadata)
  - [Metadata fields](#metadata-fields)
- [Building images](#building-images)
  - [Build one image](#build-one-image)
  - [Detect changed images](#detect-changed-images)
  - [Build selected images](#build-selected-images)
  - [Build and publish images](#build-and-publish-images)
  - [Build arguments](#build-arguments)
- [Renovate configuration](#renovate-configuration)
  - [Version annotations](#version-annotations)
  - [Automated updates](#automated-updates)
  - [Manual changes](#manual-changes)
- [GitHub Actions pipelines](#github-actions-pipelines)
  - [Pull requests](#pull-requests)
  - [Pushes to `main`](#pushes-to-main)
  - [Manual builds](#manual-builds)

## Repository layout

Each image is stored in its own directory below `dockerfiles/`.

A typical image directory contains:

```text
dockerfiles/<category>/<image>/
├── Dockerfile
├── metadata.yml
└── README.md
```

For example:

```text
dockerfiles/iac/terraform/
├── Dockerfile
├── metadata.yml
└── README.md
```

The image directory is used as the Docker build context. The build scripts locate images by finding directories that contain both:

```text
Dockerfile
metadata.yml
```

### Image metadata

Each image has a `metadata.yml` file containing static image information used by the build and publishing scripts.

Example:

```yaml
---
name: terraform
category: iac
description: Terraform with tflint and tfsec.
publish: true
registry_path: ghcr.io/redjax/dockerfiles/terraform
```

Dependency versions are not stored in `metadata.yml`. They are declared as Dockerfile `ARG` defaults and updated directly by Renovate.

### Metadata fields

| Field           | Description                                 |
| --------------- | ------------------------------------------- |
| `name`          | Local image name used during the build.     |
| `category`      | Image category.                             |
| `description`   | Human-readable image description.           |
| `publish`       | Whether the image can be published to GHCR. |
| `registry_path` | Full image path used when publishing.       |

The metadata file does not contain:

- Dependency versions.
- Docker build arguments.
- Dockerfile paths.
- Build contexts.
- Renovate configuration.

Those values are either derived from the image directory or declared in the Dockerfile.

## Building images

### Build one image

The [`build-image.sh`](../scripts/build/build-image.sh) script builds one image directory.

Example:

```shell
./scripts/build/build-image.sh \
  --image-dir dockerfiles/base/alpine \
  --tag local \
  --pull
```

The image directory must contain both:

```text
dockerfiles/base/alpine/Dockerfile
dockerfiles/base/alpine/metadata.yml
```

The Dockerfile directory is used as the build context, and the Dockerfile is loaded from:

```text
dockerfiles/base/alpine/Dockerfile
```

The resulting local image is tagged using the `name` value from `metadata.yml`:

```text
alpine:local
```

### Detect changed images

The [`determine-images-to-build.sh`](../scripts/build/determine-images-to-build.sh) script compares two Git revisions and writes the affected image directories to a build list.

```shell
./scripts/build/determine-images-to-build.sh \
  --base HEAD^ \
  --head HEAD \
  --output build_list.txt
```

The script prints the changed files and writes one image directory per line:

```text
dockerfiles/automation/taskfile
dockerfiles/base/go-ubuntu-base
```

A file changed anywhere below an image directory selects that image for building. For example, changes to any of these files select the Terraform image:

```text
dockerfiles/iac/terraform/Dockerfile
dockerfiles/iac/terraform/metadata.yml
dockerfiles/iac/terraform/README.md
dockerfiles/iac/terraform/install-tools.sh
```

To select every discovered image:

```shell
./scripts/build/determine-images-to-build.sh \
  --force \
  --output build_list.txt
```

The `--force` option belongs to the image-selection script. It does not get passed to the build-and-publish script.

### Build selected images

The [`build-and-publish-images.sh`](../scripts/build/build-and-publish-images.sh) script reads a build list and builds each selected image.

Publishing is disabled unless `--publish` is supplied:

```shell
./scripts/build/build-and-publish-images.sh \
  --pull \
  build_list.txt
```

The script skips images with:

```yaml
publish: false
```

The selected images are built using their image directories as Docker build contexts.

### Build and publish images

To build and publish the selected images:

```shell
./scripts/build/build-and-publish-images.sh \
  --pull \
  --publish \
  build_list.txt
```

Published images receive two tags:

```text
ghcr.io/redjax/dockerfiles/terraform:latest
ghcr.io/redjax/dockerfiles/terraform:<short-git-sha>
```

The Git SHA tag provides an immutable reference to the build, while `latest` points to the most recently published image.

Publishing requires authentication to GHCR:

```shell
docker login ghcr.io
```

### Build arguments

Dependency versions are declared directly in Dockerfiles:

```dockerfile
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1

FROM alpine:${ALPINE_TAG}
```

Docker uses the default value when no override is supplied:

```text
ALPINE_TAG=3.24.1
```

A different value can be supplied during a manual build:

```shell
docker build \
  --build-arg ALPINE_TAG=3.25.0 \
  --file dockerfiles/base/alpine/Dockerfile \
  dockerfiles/base/alpine
```

The repository build scripts use the defaults declared in the Dockerfile. Renovate updates those defaults when newer dependency versions are available.

Common image metadata arguments are supplied by the build scripts:

```dockerfile
ARG IMAGE_VERSION=dev
ARG IMAGE_CREATED
ARG IMAGE_SOURCE="local-build"
```

These arguments are used for OCI image labels and are not dependency versions.

## Renovate configuration

Renovate is configured in [`renovate.json`](../renovate.json).

The repository uses Renovate to update:

- Docker base image tags.
- Go versions.
- GitHub release versions.
- GitHub tag versions.
- GitHub Actions.

Renovate processes Dockerfiles with its Dockerfile manager and uses the repository’s regex custom manager for versioned Dockerfile arguments.

### Version annotations

Every versioned Dockerfile `ARG` that Renovate should manage has a comment immediately above it.

For Docker image tags:

```dockerfile
# renovate: datasource=docker depName=alpine versioning=semver
ARG ALPINE_TAG=3.24.1
```

For GitHub releases:

```dockerfile
# renovate: datasource=github-releases depName=terraform-linters/tflint extractVersion=^v(?<version>.*)$
ARG TFLINT_VERSION=0.62.0
```

For GitHub tags:

```dockerfile
# renovate: datasource=github-tags depName=golang/tools versioning=semver extractVersion=^v(?<version>.*)$
ARG GOIMPORTS_VERSION=0.49.0
```

The annotation identifies:

- The Renovate datasource.
- The dependency name.
- The versioning scheme.
- An optional expression for extracting the version from release or tag names.

For dependencies whose upstream tags include a leading `v`, the Dockerfile may store the version without the prefix and add it where required:

```dockerfile
ARG TASKFILE_VERSION=3.53.1
```

```dockerfile
"https://github.com/go-task/task/releases/download/v${TASKFILE_VERSION}/task_linux_amd64.tar.gz"
```

For Go module installation:

```dockerfile
ARG GOIMPORTS_VERSION=0.49.0
```

```dockerfile
go install golang.org/x/tools/cmd/goimports@v${GOIMPORTS_VERSION}
```

### Automated updates

Renovate opens pull requests when newer dependency versions are available.

A typical update follows this process:

1. Renovate detects a newer version.
2. Renovate updates the annotated Dockerfile `ARG`.
3. The pull request pipeline identifies the affected image directory.
4. The pull request pipeline builds the changed image.
5. A successful build satisfies the required validation check.
6. Renovate automerges the pull request when automerge is enabled.
7. The push pipeline detects the changed image after the merge.
8. The image is rebuilt and published to GHCR.

The pull request workflow validates builds but does not publish images. Publishing occurs after the changes reach `main`.

### Manual changes

Dockerfiles and metadata files can be changed manually.

Changes to files below an image directory cause that image to be selected by the change-detection script. For example, changing either of these files selects the image:

```text
dockerfiles/base/alpine/Dockerfile
dockerfiles/base/alpine/metadata.yml
```

When adding a new image:

1. Create an image directory below `dockerfiles/`.
2. Add a `Dockerfile`.
3. Add a `metadata.yml`.
4. Add a `README.md`.
5. Add Renovate annotations for managed dependency versions.
6. Build the image locally.
7. Commit the new files.

Example:

```text
dockerfiles/tools/example/
├── Dockerfile
├── metadata.yml
└── README.md
```

Example metadata:

```yaml
---
name: example
category: tools
description: Example tooling image.
publish: true
registry_path: ghcr.io/redjax/dockerfiles/example
```

## GitHub Actions pipelines

The [`build-publish.yml`](../.github/workflows/build-publish.yml) workflow handles pull-request validation, post-merge publishing, manual builds, and reusable workflow calls.

### Pull requests

When a pull request targets `main`, the workflow:

1. Determines the changed files.
2. Selects affected image directories.
3. Builds each selected image.
4. Does not publish images.

The build check should be configured as a required status check for `main`.

This allows Renovate to automerge dependency update pull requests after the affected images build successfully.

### Pushes to `main`

When changes are pushed to `main`, the workflow:

1. Compares the previous `main` commit with the new commit.
2. Selects changed image directories.
3. Builds the selected images.
4. Logs in to GHCR.
5. Publishes images with `publish: true`.

A merged Renovate pull request therefore causes only the affected images to be rebuilt and published.

### Manual builds

The workflow supports `workflow_dispatch` for on-demand builds.

To build one image, provide its directory:

```text
image: dockerfiles/base/alpine
```

To build every image:

```text
force: true
```

To publish the result:

```text
enable_publish: true
```

To perform a dry run:

```text
dry_run: true
```

To always pull base images:

```text
pull: true
```

Example manual configurations:

| Purpose                       | `image`                   | `force` | `dry_run` | `enable_publish` |
| ----------------------------- | ------------------------- | ------: | --------: | ---------------: |
| Build one image locally in CI | `dockerfiles/base/alpine` | `false` |   `false` |          `false` |
| Build all images              | empty                     |  `true` |   `false` |          `false` |
| Dry-run one image             | `dockerfiles/base/alpine` | `false` |    `true` |          `false` |
| Build and publish one image   | `dockerfiles/base/alpine` | `false` |   `false` |           `true` |
| Build and publish all images  | empty                     |  `true` |   `false` |           `true` |
