#!/bin/bash
# 自架 RO 伺服器的管理工具（macOS 內建 bash 3.2 也能跑）
set -euo pipefail
cd "$(dirname "$0")"

dc() { docker compose "$@"; }
die() { echo "錯誤：$*" >&2; exit 1; }
need_env() { [ -f .env ] || die "還沒有 .env，先執行 ./ro.sh setup"; }
sql() { dc exec -T db sh -c 'mariadb -uragnarok -p"$MARIADB_PASSWORD" ragnarok' "$@"; }

usage() {
  cat <<USAGE
用法：./ro.sh <指令>

  setup                      第一次使用：產生 .env（含隨機密碼）
  start                      編譯（第一次約 5–15 分鐘）並啟動伺服器
  stop | restart | status
  logs [login|char|map]      看伺服器輸出（Ctrl+C 離開）
  rebuild                    改了 PACKETVER 之後重新編譯
  account <帳號> <密碼> [M|F] 建立遊戲帳號
  gm <帳號> [等級]            把帳號設成 GM（預設 99 = 最高管理員）
  sql                        進入資料庫命令列
  launcher <Ragexe.exe 路徑> [CrossOver 容器名稱]
                             產生 ~/Applications/MyRO.app，可加進 Steam
  reset                      刪除所有資料（角色、帳號全部清空）
USAGE
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  setup)
    [ -f .env ] && die ".env 已存在；要重來請先刪除它"
    command -v docker >/dev/null || die "找不到 docker，請先安裝 OrbStack 或 Docker Desktop"
    awk -v db="$(openssl rand -hex 16)" -v inter="$(openssl rand -hex 12)" '
      /^DB_PASS=/ { print "DB_PASS=" db; next }
      /^INTER_PASS=/ { print "INTER_PASS=" inter; next }
      { print }' .env.example > .env
    echo "已產生 .env。接著執行：./ro.sh start"
    ;;
  start)   need_env; dc up -d --build; echo "啟動中，用 ./ro.sh logs map 看到 'Server is ready' 就可以登入了" ;;
  stop)    dc down ;;
  restart) need_env; dc up -d --force-recreate ;;
  status)  dc ps ;;
  logs)    dc logs -f --tail 100 "$@" ;;
  rebuild) need_env; dc build --no-cache && dc up -d --force-recreate ;;
  account)
    [ $# -ge 2 ] || die "用法：./ro.sh account <帳號> <密碼> [M|F]"
    user="$1"; pass="$2"; sex="${3:-M}"
    [[ "$user" =~ ^[A-Za-z0-9_]{4,23}$ ]] || die "帳號只能用英數字和底線，4–23 個字"
    [[ "$pass" =~ ^[A-Za-z0-9_.@#%+=-]{4,32}$ ]] || die "密碼 4–32 個字，只能用英數字和 _.@#%+=-"
    [[ "$sex" =~ ^[MF]$ ]] || die "性別只能是 M 或 F"
    echo "INSERT INTO login (userid, user_pass, sex, email) VALUES ('$user', '$pass', '$sex', 'a@a.com');" | sql \
      && echo "已建立帳號 $user"
    ;;
  gm)
    [ $# -ge 1 ] || die "用法：./ro.sh gm <帳號> [等級]"
    user="$1"; level="${2:-99}"
    [[ "$user" =~ ^[A-Za-z0-9_]{4,23}$ ]] || die "帳號格式不對"
    [[ "$level" =~ ^[0-9]{1,2}$ ]] || die "等級要是 0–99"
    n="$(echo "UPDATE login SET group_id=$level WHERE userid='$user' AND sex<>'S'; SELECT ROW_COUNT();" | sql -N)"
    [ "$n" = "1" ] || die "找不到帳號 $user"
    echo "$user 現在是 group $level（角色要重新登入才會生效）"
    ;;
  sql) dc exec db sh -c 'mariadb -uragnarok -p"$MARIADB_PASSWORD" ragnarok' ;;
  launcher)
    [ $# -ge 1 ] || die "用法：./ro.sh launcher <Ragexe.exe 的完整路徑> [CrossOver 容器名稱]"
    exe="$1"; bottle="${2:-}"
    [ -f "$exe" ] || die "找不到 $exe"
    exe_dir="$(cd "$(dirname "$exe")" && pwd)"; exe_name="$(basename "$exe")"
    server_dir="$(pwd)"
    app="$HOME/Applications/MyRO.app"
    mkdir -p "$app/Contents/MacOS"
    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>MyRO</string>
  <key>CFBundleIdentifier</key><string>local.myro.launcher</string>
  <key>CFBundleExecutable</key><string>MyRO</string>
  <key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
    cat > "$app/Contents/MacOS/MyRO" <<LAUNCH
#!/bin/bash
# 由 ro.sh launcher 產生：先確保伺服器開著，再用 Wine 開客戶端
export PATH="/opt/homebrew/bin:/usr/local/bin:\$HOME/.orbstack/bin:/Applications/Docker.app/Contents/Resources/bin:\$PATH"
"$server_dir/ro.sh" start >/dev/null 2>&1 || true
cd "$exe_dir"
CX="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
if [ -x "\$CX" ]; then
  exec "\$CX" ${bottle:+--bottle "$bottle"} "$exe_name"
else
  exec wine "$exe_name"
fi
LAUNCH
    chmod +x "$app/Contents/MacOS/MyRO"
    echo "已建立 $app"
    echo "Steam → 遊戲 → 新增非 Steam 遊戲到我的收藏庫 → 瀏覽 → 選 MyRO.app"
    ;;
  reset)
    read -r -p "會刪除所有帳號和角色，確定嗎？輸入 yes：" ans
    [ "$ans" = yes ] && dc down -v && echo "已清空"
    ;;
  *) usage ;;
esac
