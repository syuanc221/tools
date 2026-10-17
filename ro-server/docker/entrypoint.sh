#!/bin/bash
# 用法：entrypoint.sh init|login|char|map
set -euo pipefail

: "${DB_HOST:=db}" "${DB_NAME:=ragnarok}" "${DB_USER:=ragnarok}" "${DB_PASS:?DB_PASS 未設定}"
: "${INTER_USER:=s1}" "${INTER_PASS:?INTER_PASS 未設定}"
: "${PUBLIC_IP:=127.0.0.1}" "${SERVER_NAME:=MyRO}"
: "${ALLOW_REGISTER:=yes}" "${PINCODE:=no}"

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
login_ip: login
char_ip: ${PUBLIC_IP}
pincode_enabled: ${PINCODE}
CONF
  cat > conf/import/map_conf.txt <<CONF
userid: ${INTER_USER}
passwd: ${INTER_PASS}
char_ip: char
map_ip: ${PUBLIC_IP}
CONF
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
