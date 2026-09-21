# DSH-Docker

Build a frozen Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).

This repository does **not** publish images to GHCR, Docker Hub, or any package registry. GitHub Actions only builds the image, exports it with `docker save`, and uploads the resulting archive as a workflow artifact.

## Frozen inputs

- DeepSeek Harness: `0.1.6-alpha.2`
- Upstream commit: `ddefc45fbc7f8e46dd73185e68295696d1297887`
- pnpm: `11.7.0` (declared by upstream)
- Node.js image: `node:22.19.0-bookworm`
- Node.js image index digest: `sha256:afff6d8c97964a438d2e6a9c96509367e45d8bf93f790ad561a1eaea926303d9`
- `actions/checkout`: `v7.0.1`, pinned to `3d3c42e5aac5ba805825da76410c181273ba90b1`
- `actions/upload-artifact`: `v7.0.1`, pinned to `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`

The Docker build checks out the exact upstream commit and runs `pnpm install --frozen-lockfile`, so the dependency graph is taken from that immutable upstream lockfile.

## Build locally

```sh
docker build --platform=linux/amd64 -t dsh:0.1.6-alpha.2 .
```

Run the CLI:

```sh
docker run --rm -it \
  -v "$PWD:/workspace" \
  dsh:0.1.6-alpha.2 --help
```

Run a task:

```sh
docker run --rm -it \
  -v "$PWD:/workspace" \
  dsh:0.1.6-alpha.2 "your task"
```

## Web UI

Upstream intentionally binds `dsh web` to `127.0.0.1` and rejects `--host 0.0.0.0`. This image does not patch or weaken that security behavior.

On Linux, host networking can preserve the upstream loopback model:

```sh
docker run --rm -it \
  --network host \
  -v "$PWD:/workspace" \
  dsh:0.1.6-alpha.2 web --no-open
```

## CI artifact

Run the "Build Docker artifact" workflow manually, or push changes affecting the Docker build/workflow.

The workflow produces:

```text
deepseek-harness-0.1.6-alpha.2-linux-amd64.tar.gz
```

Load it with:

```sh
gzip -dc deepseek-harness-0.1.6-alpha.2-linux-amd64.tar.gz | docker load
```

## Security note

DeepSeek Harness is upstream developer-preview software and can execute model-generated commands. The container runs the Harness process as the unprivileged `node` user, but containerization is not a complete security boundary for untrusted workloads.
