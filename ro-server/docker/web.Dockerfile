# 網頁版 RO 客戶端：roBrowserLegacy（遊戲畫面）+ RemoteClient-JS（從 .grf 讀素材、WebSocket 轉接）
# node 完整版映像已內建 git，不用另外 apt 安裝
FROM node:24-bookworm AS build

ARG ROBROWSER_REPO=https://github.com/MrAntares/roBrowserLegacy.git
ARG ROBROWSER_REF=9f3281c02fee66f8be949b7e58429dc49775a7be
WORKDIR /src
RUN git init -q . \
 && git fetch -q --depth 1 "$ROBROWSER_REPO" "$ROBROWSER_REF" \
 && git checkout -q FETCH_HEAD \
 && ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm install --legacy-peer-deps --no-audit --no-fund \
 && npm run build -- -O -T -H

FROM node:24-bookworm AS remote-client
ARG REMOTE_CLIENT_REPO=https://github.com/FranciscoWallison/roBrowserLegacy-RemoteClient-JS.git
ARG REMOTE_CLIENT_REF=0dd3a3fa71733c0c88ac1beb117039174eb2a7b0
WORKDIR /app
RUN git init -q . \
 && git fetch -q --depth 1 "$REMOTE_CLIENT_REPO" "$REMOTE_CLIENT_REF" \
 && git checkout -q FETCH_HEAD \
 && npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
 && rm -rf .git

FROM node:24-bookworm-slim
COPY --from=remote-client /app /app
WORKDIR /app
COPY --from=build /src/dist/Web /robrowser
COPY web-entrypoint.sh /web-entrypoint.sh
RUN chmod +x /web-entrypoint.sh

ENV NODE_ENV=production \
    ENABLE_WSPROXY=true \
    ENABLE_STATIC_SERVE=true \
    ROBROWSER_PATH=/robrowser
ENTRYPOINT ["/web-entrypoint.sh"]
