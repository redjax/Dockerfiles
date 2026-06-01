# gitlab-docker-base

Focused GitLab CI base image for jobs that need Docker CLI access and standard shell tools.

Included tools:

- docker CLI (from upstream `docker:<tag>-cli` image)
- bash
- coreutils
- git
- curl

This image is intentionally minimal. Use other variants for Python/Node workflows.
