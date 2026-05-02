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

A collection of my Dockerfiles organized by category. Pipeline automations check for image & tool updates each night. When new tags & releases are available, the pipeline rebuilds & releases the containers to the [package registry](https://github.com/redjax?tab=packages&repo_name=Dockerfiles).

See the [usage docs](./docs/USAGE.md) for more information.

The [`nightly-update` pipeline](https://github.com/redjax/Dockerfiles/actions/workflows/nightly-update.yml) runs each night to check for new upstream tags and rebuild containers. Read more about this repository's pipelines in the [pipeline docs](./docs/PIPELINES.md).
