# Pipelines <!-- omit in toc -->

This repository uses GitHub Actions to keep image manifests current and to build and publish container images when their manifests change.

The pipelines are split into small, reusable workflows so they can run on demand or chained together, or scheduled from a single pipeline.

Pipeline logic lives in the [`scripts/`](../scripts/) directory wherever possible. This keeps the workflow files focused on orchestration and makes the update/build logic easier to reuse locally or move to a different platform later.

## Table of Contents <!-- omit in toc -->

- [Workflows](#workflows)
- [Tag bump](#tag-bump)
- [Build and publish](#build-and-publish)
- [Nightly pipeline](#nightly-pipeline)

## Workflows

The repository uses three workflow entry points:

- [`update-images.yml`](../.github/workflows/update-images.yml) updates image manifests when a newer upstream release is available.
- [`build-publish.yml`](../.github/workflows/build-publish.yml) builds and publishes container images defined by `image.yml`.
- [`nightly-update.yml`](../.github/workflows/nightly-update.yml) runs the update and build workflows together on a schedule.

Each workflow can also be run manually, which makes it easier to test one stage without running the entire pipeline, or do emergency patches.

## Tag bump

The tag bump workflow scans the repository for `image.yml` manifests and checks each one for a newer upstream version. When a new version is available, it updates the manifest and any associated Dockerfile arguments that depend on that version. This workflow is intended to keep image definitions current without requiring manual edits for each upstream release.

When `dry_run` is enabled, the workflow previews the changes without committing them. When `dry_run` is disabled, the workflow commits the updated files back to the repository.

## Build and publish

The build and publish workflow reads the same `image.yml` manifests and builds the images marked for publication. Only images with `publish: true` are included in the publish step. Each image is tagged with its version from the manifest, `latest`, and a short commit SHA so the published image is easy to identify later.

When `dry_run` is enabled, the workflow prints the commands it would run instead of pushing images to GHCR. When `dry_run` is disabled, the workflow builds the image locally, applies the tags, and pushes them to the registry.

## Nightly pipeline

The nightly pipeline orchestrates the tag bump and build/publish pipelines into a scheduled task. It first runs the update workflow, then runs the build and publish workflow. This keeps images up to date with their upstream versions, and ensures the new versions are published to my container registry.
