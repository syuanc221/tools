#!/bin/bash
# 用法：entrypoint.sh init|login|char|map
# 所有容器共用同一個網路（network_mode: service:db），所以彼此都用 127.0.0.1 連線
set -euo pipefail

: "${DB_HOST:=127.0.0.1}" "${DB_NAME:=ragnarok}" "${DB_USER:=ragnarok}" "${DB_PASS:?DB_PASS 未設定}"
: "${INTER_USER:=s1}" "${INTER_PASS:?INTER_PASS 未設定}"
: "${PUBLIC_IP:=127.0.0.1}" "${SERVER_NAME:=MyRO}"
: "${ALLOW_REGISTER:=yes}" "${PINCODE:=no}" "${PVP_MODE:=yes}"

mysql_cmd() { mariadb -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"; }

# 把設定寫進 conf/import（rAthena 會優先讀取這裡，不用改原始設定檔）
write_conf() {
  [ -d conf/import ] || cp -r conf/import-tmpl conf/import

  : > conf/import/inter_conf.txt
  for p in login_server ipban_db char_server map_server web_server log_db; do
    printf '%s_ip: %s\n%s_id: %s\n%s_pw: %s\n%s_db: %s\n' \
      "$p" "$DB_HOST" "$p" "$DB_USER" "$p" "$DB_PASS" "$p" "$DB_NAME" >> conf/import/inter_conf.txt
  done

  cat > conf/import/login_conf.txt <<CONF
new_account: ${ALLOW_REGISTER}
CONF

  cat > conf/import/char_conf.txt <<CONF
userid: ${INTER_USER}
passwd: ${INTER_PASS}
server_name: ${SERVER_NAME}
login_ip: 127.0.0.1
char_ip: ${PUBLIC_IP}
pincode_enabled: ${PINCODE}
CONF

  cat > conf/import/map_conf.txt <<CONF
userid: ${INTER_USER}
passwd: ${INTER_PASS}
char_ip: 127.0.0.1
map_ip: ${PUBLIC_IP}
CONF

  if [ "$PVP_MODE" = yes ]; then
    # 新角色直接出生在普隆德拉，載入 PvP 用的 NPC（npc/myro 由 docker-compose 掛載 ./pvp）
    cat >> conf/import/char_conf.txt <<CONF
start_point_pre: prontera,156,185
start_point: prontera,156,185
CONF
    cat >> conf/import/map_conf.txt <<CONF
npc: npc/custom/healer.txt
npc: npc/custom/warper.txt
npc: npc/custom/stylist.txt
npc: npc/myro/pvp.txt
CONF
    cp npc/myro/groups.yml conf/import/groups.yml
  else
    cp conf/import-tmpl/groups.yml conf/import/groups.yml
  fi
}

wait_db() {
  echo "等待資料庫 ${DB_HOST} ..."
  until mysql_cmd -e 'SELECT 1' >/dev/null 2>&1; do sleep 2; done
}

write_conf
wait_db

case "${1:-}" in
  init)
    if ! mysql_cmd -e 'SELECT 1 FROM `login` LIMIT 1' >/dev/null 2>&1; then
      echo "第一次啟動：匯入資料表 ..."
      mysql_cmd < sql-files/main.sql
      mysql_cmd < sql-files/logs.sql
    fi
    # 伺服器之間互連用的帳號（account_id 1），改成 .env 裡的隨機密碼
    mysql_cmd -e "UPDATE \`login\` SET userid='${INTER_USER}', user_pass='${INTER_PASS}' WHERE account_id=1 AND sex='S';"
    echo "資料庫已就緒"
    ;;
  login) exec ./login-server ;;
  char)  exec ./char-server ;;
  map)   exec ./map-server ;;
  *) echo "未知角色：${1:-}（應為 init|login|char|map）" >&2; exit 1 ;;
esac
