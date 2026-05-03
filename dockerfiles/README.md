# Docker Images <!-- omit in toc -->

The directories in this path are image categories. For example, the `gitleaks` container is a security tool, so it's in [`tools/security/gitleaks/`](./tools/security/gitleaks/).

Images in the [`base/` directory](./base/) are my custom images based on an upstream. For example, [`base/debian/`](./base/debian) is a container that pins to the [upstream `debian` image](https://hub.docker.com/_/debian) and installs some extra tools. Images based on the `base/debian` container will have the same patches as the upstream image, and access to the other tools I layer in.

All Dockerfiles have an `image.yml` file, which acts as that image's manifest. The [build scripts](../scripts/build/) and [update scripts](../scripts/update/) interact with this manifest file to automatically bump tool and upstream versions, define the way an image should be built, and pass build args into the scripts when they build an image.

Some images, like the [`terraform-tools` image](./tools/iac/terraform/), install tools from external sources, like [tflint](https://github.com/terraform-linters/tflint). These are treated as "components," extra tools that are not an upstream image but should still receive version bumps. The scripts know how to use the `components:` section in the [`image.yml` file](./tools/iac/terraform/image.yml).

Read more about how this repository uses the `image.yml` manifest in [the Dockerfile docs](../docs/DOCKERFILES.md).
