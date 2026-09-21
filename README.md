# DSH-Docker

Build a frozen Docker image for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).

GitHub Actions builds the image exactly once, then derives two outputs from that single build:

- a `docker save` archive uploaded as a workflow artifact;
- a published image on GHCR: `ghcr.io/openlistteam/dsh-docker`.

Nothing is published to Docker Hub.

## Frozen inputs

- DeepSeek Harness: `0.1.6-alpha.2`
- Upstream commit: `ddefc45fbc7f8e46dd73185e68295696d1297887`
- pnpm: `11.7.0` (declared by upstream)
- Node.js image: `node:22.19.0-bookworm`
- Node.js image index digest: `sha256:afff6d8c97964a438d2e6a9c96509367e45d8bf93f790ad561a1eaea926303d9`
- `actions/checkout`: `v7.0.1`, pinned to `3d3c42e5aac5ba805825da76410c181273ba90b1`
- `actions/upload-artifact`: `v7.0.1`, pinned to `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`

The Docker build checks out the exact upstream commit and runs `pnpm install --frozen-lockfile`, so the dependency graph is taken from that immutable upstream lockfile.

GHCR login uses the built-in `GITHUB_TOKEN` through the plain `docker login` CLI, so the workflow adds no further third-party actions and requires no extra repository secret.

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

## CI: artifact and GHCR

Run the "Build and publish Docker image" workflow manually, or push changes affecting the Docker build/workflow on `main`.

The image is built once at `linux/amd64` and smoke-tested with `--version` before anything is published.

### Workflow artifact

```text
deepseek-harness-0.1.6-alpha.2-linux-amd64.tar.gz
```

Load it with:

```sh
gzip -dc deepseek-harness-0.1.6-alpha.2-linux-amd64.tar.gz | docker load
```

### GHCR image

Tags pushed for each published build:

| Tag | Meaning |
| --- | --- |
| `0.1.6-alpha.2` | frozen DeepSeek Harness version |
| `sha-<short>` | commit that produced the build |
| `latest` | most recent build from `main` |

```sh
docker pull ghcr.io/openlistteam/dsh-docker:0.1.6-alpha.2
```

The workflow only authenticates and pushes when the run is on `main` (a push to `main`, or a manual dispatch from `main`). Builds from other refs still produce the artifact but never touch the registry, so a work-in-progress branch can never move `latest`.

Notes and limitations:

- Only `linux/amd64` is published, matching the single-platform build above.
- The push uses the local Docker daemon rather than Buildx, so the image carries no BuildKit provenance/SBOM attestations. The OCI labels baked into the Dockerfile (`source`, `version`, `revision`) still link the package to this repository.
- The package is created on the first successful push. Set its visibility (public/private) in the package settings on GitHub; if the owning organization restricts package creation via `GITHUB_TOKEN`, fall back to a PAT with `write:packages`.

## Security note

DeepSeek Harness is upstream developer-preview software and can execute model-generated commands. The container runs the Harness process as the unprivileged `node` user, but containerization is not a complete security boundary for untrusted workloads.
