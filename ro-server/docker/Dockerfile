# rAthena 伺服器映像：在 Mac（Intel / Apple Silicon）上的 Docker 都能直接編譯執行
FROM ubuntu:24.04 AS build
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates git make gcc g++ zlib1g-dev libmariadb-dev libmariadb-dev-compat \
 && rm -rf /var/lib/apt/lists/*

ARG RATHENA_REPO=https://github.com/rathena/rathena.git
ARG RATHENA_REF=d4b8e7b8f16061cc2496d377ac8f777ce72a4f39
# 封包版本（客戶端日期）。網頁客戶端會自動用同一個值
ARG PACKETVER=20130618
# yes = 經典版（復興前），no = 復興後
ARG PRERE=yes

WORKDIR /rathena
RUN git init -q . \
 && git fetch -q --depth 1 "$RATHENA_REPO" "$RATHENA_REF" \
 && git checkout -q FETCH_HEAD \
 && ./configure --enable-packetver="$PACKETVER" --enable-prere="$PRERE" \
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
