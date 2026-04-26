# Usage

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
