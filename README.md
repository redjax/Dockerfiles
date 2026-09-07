# Dockerfiles

<!-- Repo image -->
<p align="center">
  <a href="https://github.com/redjax/Dockerfiles">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset=".assets/img/docker-header.png">
      <img src=".assets/img/docker-header.png" height="300">
    </picture>
  </a>
</p>

<!-- Git Badges -->
<p align="center">
  <a href="https://github.com/redjax/dockerfiles">
    <img alt="Created At" src="https://img.shields.io/github/created-at/redjax/dockerfiles">
  </a>
  <a href="https://github.com/redjax/dockerfiles/commit">
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/redjax/dockerfiles">
  </a>
  <a href="https://github.com/redjax/dockerfiles/commit">
    <img alt="Commits this year" src="https://img.shields.io/github/commit-activity/y/redjax/dockerfiles">
  </a>
  <a href="https://github.com/redjax/dockerfiles">
    <img alt="Repo size" src="https://img.shields.io/github/repo-size/redjax/dockerfiles">
  </a>
</p>

---

A collection of my Dockerfiles organized by category. [Renovate](https://github.com/renovatebot/renovate) automations keep Docker image tags and CLI tooling versions fresh & updated.

When new tags & releases are available, Renovate opens PRs that bump version pins and, once auto-merged, triggers the build pipeline to rebuild & publish changed containers to the [package registry](https://github.com/redjax?tab=packages&repo_name=Dockerfiles).

See the [usage docs](./docs/USAGE.md) for more information.

## Quickstart

To pull and run an image from the [container registry](https://github.com/redjax?tab=packages&repo_name=Dockerfiles), run:

```shell
docker pull ghcr.io/redjax/dockerfiles/<container-name>:<tag>
```

For example, to pull the [`dockerfiles/taskfile` container](https://github.com/redjax/Dockerfiles/pkgs/container/dockerfiles%2Ftaskfile), run:

```shell
docker pull ghcr.io/redjax/dockerfiles/taskfile:<version, commit hash, or 'latest'>
```

Then you can run the container with:

```shell
docker run ghcr.io/redjax/dockerfiles/taskfile:<commitish> [commands]
```

These images can also be used as pipeline runner images.
