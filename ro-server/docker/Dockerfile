# rAthena 伺服器映像：在 Mac（Intel / Apple Silicon）上的 Docker 都能直接編譯執行
FROM ubuntu:24.04 AS build
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates git make gcc g++ zlib1g-dev libmariadb-dev libmariadb-dev-compat \
 && rm -rf /var/lib/apt/lists/*

ARG RATHENA_REPO=https://github.com/rathena/rathena.git
ARG RATHENA_REF=d4b8e7b8f16061cc2496d377ac8f777ce72a4f39
# 必須跟你的客戶端 exe 日期一致（例如 2021-11-03 的客戶端 => 20211103）
ARG PACKETVER=20211103

WORKDIR /rathena
RUN git init -q . \
 && git fetch -q --depth 1 "$RATHENA_REPO" "$RATHENA_REF" \
 && git checkout -q FETCH_HEAD \
 && ./configure --enable-packetver="$PACKETVER" \
 && make server -j"$(nproc)" \
 && rm -rf .git src 3rdparty/*/src

FROM ubuntu:24.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libmariadb3 zlib1g mariadb-client \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /rathena /rathena
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
WORKDIR /rathena
ENTRYPOINT ["/entrypoint.sh"]
