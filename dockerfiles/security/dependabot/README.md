# Tool: Dependabot

[Dependabot](https://github.com/dependabot/cli) is a tool for automated dependency updates.

## Build

```shell
docker build \
    --tag dependabot-cli:1.91.0 \
    --build-arg DEPENDABOT_VERSION=1.91.0 \
    .
```
