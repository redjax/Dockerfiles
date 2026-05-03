# Taskfile

Alpine container for [`taskfile/task`](https://taskfile.dev).

`task` is a cross-platform build tool inspired by Make. It uses [`Taskfile.yml` files](https://taskfile.dev/docs/guide) to create YAML pipelines you can run anywhere.

## Build

```shell
docker build \
    --tag ghcr.io/redjax/Dockerfiles/taskfile:latest \
    --build-arg TASKFILE_VERSION="" \
    .
```

## Usage

The Dockerfile uses the `task` bin's path as the `ENTRYPOINT`, so you can run `task` commands directly. The default command is `-h`.

If you run `docker run --rm -it ghcr.io/redjax/Dockerfiles/taskfile:latest`, you will see `task`'s help menu. To run a different command, mount a volume with a `Taskfile.yml`, or a path where the tasks will be initialized.

Initialize a `Taskfile.yml`:

```shell
docker run --rm -it \
    -v "${PWD}:/work" \
    ghcr.io/redjax/Dockerfiles/taskfile:latest \
    --init
```

Print tasks found in `$PWD`:

```shell
docker run --rm -it \
    -v "${PWD}:/work" \
    ghcr.io/redjax/Dockerfiles/taskfile:latest \
    -l
```

Call a task named `build:dockerfile` (this task must exist in a `Taskfile.yml` in the `$PWD` mounted at `/work` in the container):

```shell
docker run --rm -it \
    -v "${PWD}:/work" \
    ghcr.io/redjax/Dockerfiles/taskfile:latest \
    build:docker
```
