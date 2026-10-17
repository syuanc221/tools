#!/bin/bash
# 依 .env 產生網頁客戶端的設定，然後啟動素材伺服器 + WebSocket 轉接
set -euo pipefail

: "${SERVER_NAME:=MyRO}" "${PACKETVER:=20130618}" "${PRERE:=yes}" "${LANGTYPE:=1}"
: "${WEB_PORT:=3338}" "${PUBLIC_IP:=127.0.0.1}"

renewal=true; [ "$PRERE" = yes ] && renewal=false

# 瀏覽器連到哪個網址，就從同一個網址拿素材、走 WebSocket，所以朋友用區網 IP 開也能玩。
# 遊戲伺服器在容器裡都是 127.0.0.1，WebSocket 轉接只允許連到那三個埠。
cat > /robrowser/Config.local.js <<JS
window.ROConfigLocal = {
	remoteClient: location.origin + '/',
	skipIntro: true,
	skipServerList: true,
	enableCashShop: false,
	enableBank: false,
	enableAchievements: false,
	enableCheckAttendance: false,
	enableMapName: false,
	enableDmgSuffix: false,
	servers: [{
		display: '${SERVER_NAME}',
		desc: '${SERVER_NAME}',
		address: '127.0.0.1',
		port: 6900,
		version: 55,
		langtype: ${LANGTYPE},
		packetver: ${PACKETVER},
		renewal: ${renewal},
		packetKeys: false,
		forceUseAddress: true,
		socketProxy: (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws/',
		adminList: []
	}]
};
JS

export PORT="$WEB_PORT"
export CLIENT_PUBLIC_URL="http://localhost:${WEB_PORT}"
export CORS_ORIGINS="http://localhost:${WEB_PORT},http://127.0.0.1:${WEB_PORT},http://${PUBLIC_IP}:${WEB_PORT}"

# 沒有 DATA.INI 就自動產生：其他 .grf 優先，data.grf 放最後
if [ ! -f resources/DATA.INI ]; then
  shopt -s nullglob nocaseglob
  grfs=(resources/*.grf)
  if [ ${#grfs[@]} -eq 0 ]; then
    echo "client/ 資料夾裡沒有 .grf —— 把客戶端的 data.grf（和其他 .grf、BGM 資料夾）放進 ro-server/client/ 再 ./ro.sh restart" >&2
    exit 1
  fi
  {
    echo "[Data]"
    i=0
    for g in "${grfs[@]}"; do
      [[ "${g,,}" == */data.grf ]] && continue
      echo "$i=$(basename "$g")"; i=$((i + 1))
    done
    for g in "${grfs[@]}"; do
      [[ "${g,,}" == */data.grf ]] && echo "$i=$(basename "$g")"
    done
  } > resources/DATA.INI
  echo "已自動產生 client/DATA.INI："; cat resources/DATA.INI
fi
# 背景音樂是選用的，有 client/BGM 才開
[ -d resources/BGM ] && export BGM_PATH=/app/resources/BGM

exec node start-prod.js
