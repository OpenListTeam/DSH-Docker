# syntax=docker/dockerfile:1

ARG NODE_IMAGE=node:22.19.0-bookworm@sha256:afff6d8c97964a438d2e6a9c96509367e45d8bf93f790ad561a1eaea926303d9

FROM ${NODE_IMAGE} AS build

ARG DSH_REPOSITORY=https://github.com/deepseek-ai/deepseek-harness.git
ARG DSH_COMMIT=ddefc45fbc7f8e46dd73185e68295696d1297887
ARG PNPM_VERSION=11.7.0

WORKDIR /opt

RUN corepack enable \
 && corepack prepare "pnpm@${PNPM_VERSION}" --activate \
 && git clone --filter=blob:none --no-checkout "${DSH_REPOSITORY}" deepseek-harness \
 && cd deepseek-harness \
 && git fetch --depth=1 origin "${DSH_COMMIT}" \
 && git checkout --detach "${DSH_COMMIT}" \
 && test "$(git rev-parse HEAD)" = "${DSH_COMMIT}" \
 && git remote remove origin

WORKDIR /opt/deepseek-harness

RUN pnpm install --frozen-lockfile
RUN pnpm run build

FROM ${NODE_IMAGE} AS runtime

ARG DSH_COMMIT=ddefc45fbc7f8e46dd73185e68295696d1297887
ARG DSH_VERSION=0.1.6-alpha.2
LABEL org.opencontainers.image.title="DeepSeek Harness" \
      org.opencontainers.image.description="Frozen DeepSeek Harness Docker build" \
      org.opencontainers.image.source="https://github.com/OpenListTeam/DSH-Docker" \
      org.opencontainers.image.version="${DSH_VERSION}" \
      org.opencontainers.image.revision="${DSH_COMMIT}"

RUN corepack enable \
 && corepack prepare "pnpm@${PNPM_VERSION}" --activate

COPY --from=build --chown=node:node /opt/deepseek-harness /opt/deepseek-harness

WORKDIR /workspace
USER node

ENV HOME=/home/node \
    NODE_ENV=production

ENTRYPOINT ["node", "/opt/deepseek-harness/apps/cli/lib/bin.js"]
CMD ["--help"]
