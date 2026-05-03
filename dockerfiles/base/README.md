# Base Images

Dockerfiles pinned to an upstream release, with extra layers for additional tooling. For example, the [`debian` base](./debian/) pins to an [upstream `debian` tag](https://hub.docker.com/_/debian) and installs tools like `curl` and `jq`. The [nightly pipeline](../../.github/workflows/nightly-update.yml) keeps the base images up  to date with their upstream tags.
