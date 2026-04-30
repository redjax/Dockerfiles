# Tool: KICS

[KICS](https://github.com/Checkmarx/kics) is a code & vulnerability scanner for IaC. It can scan Terraform, Docker, Kubernetes, and more.

## Build

```shell
docker build \
    --tag kics:latest \
    --build-arg ALPINE_TAG=3.20
    --build-arg KICS_TAG=2.1.20 \
    .
```

## Usage

Pull the image with `docker pull ghcr.io/redjax/Dockerfiles/kics:$TAG`.

- Run a scan of the current directory:

  ```shell
  docker run \
    --rm \
    -v "${PWD}:/scan" \
    -v "./kics-scan-results:/out" \
    ghcr.io/redjax/Dockerfiles/kics:$TAG \
    scan -p /scan -o /out --report-formats json --output-name result-file-name-with-no-ext

  ```

- Run a scan of a target directory:

  ```shell
  docker run  \
    --rm \
    -v "/path/to/scan:/scan" \
    -v "./kics-scan-results:/out" \
    ghcr.io/redjax/Dockerfiles/kics:$TAG \
    scan -p /scan -o /out --report-formats json --output-name result-file-name-with-no-ext
  ```
