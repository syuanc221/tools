# MyRO：在 Mac 上自架經典 RO 私服（網頁版、純 PvP）

不用 Windows、不用裝客戶端，**打開瀏覽器就能玩**，朋友連你的網址就能一起打 PvP、聊天。

- 伺服器：開源模擬器 [rAthena](https://github.com/rathena/rathena)，預設是**經典版（復興前）**
- 客戶端：[roBrowserLegacy](https://github.com/MrAntares/roBrowserLegacy)，用瀏覽器跑的 RO，介面會照 `PACKETVER` 的日期顯示當年的樣子
- 預設開啟**純 PvP 模式**：出生在普隆德拉，找「PvP 大師」一鍵轉生二轉、練到 99/70，裝備用 `@item` 自己拿

> 只適合自己和認識的朋友玩。RO 的素材版權屬於 Gravity，請不要公開架站營利或散布素材。

```
你的 Mac（Docker）
├─ db     資料庫
├─ login / char / map   rAthena 伺服器
└─ web    網頁客戶端 + 素材 + WebSocket 轉接  ← 瀏覽器開 http://localhost:3338
```

## 需要準備

1. **[OrbStack](https://orbstack.dev)**（推薦，輕量）或 Docker Desktop，裝好打開就行。Apple Silicon 和 Intel 都可以。
2. **客戶端素材**：從論壇下載的 RO 客戶端裡的 `data.grf`（有 `rdata.grf`、`BGM` 資料夾也一起拿）。
   - `.grf` 要是**沒加密的 0x200 版本**，論壇大部分的客戶端都是。
   - 素材越新越好，舊日期的版本也能顯示（反過來不行）。

## 安裝（第一次）

```bash
cd ro-server
./ro.sh setup        # 產生 .env，裡面有隨機密碼
```

把 `data.grf`（和其他 `.grf`、`BGM/` 資料夾）複製到 `ro-server/client/`，然後：

```bash
./ro.sh start        # 第一次會編譯，大約 5–15 分鐘
./ro.sh logs map     # 看到 "Server is ready" 就好了，Ctrl+C 離開
./ro.sh open         # 用瀏覽器打開遊戲
```

登入畫面輸入 `帳號_M`（男）或 `帳號_F`（女）加密碼就會自動註冊，下次登入不用加 `_M`。
想當 GM 管理伺服器：`./ro.sh gm 帳號`

> 想要像一般 App：Safari 打開遊戲後，選單「檔案 → 加入 Dock」，之後從 Dock 點就能開。

## 純 PvP 怎麼玩

| 在哪 | 做什麼 |
|---|---|
| 普隆德拉噴水池旁的 **PvP 大師** | 一鍵轉職練滿、領補給品（藥水、果實、瓶子、礦石）、傳送到競技場、重新分配點數 |
| 指令 `@item <物品ID> [數量]` | 自己拿裝備，例如 `@item 1162`（雙手劍 Broad Sword） |
| `@item2` | 拿插好卡片的裝備 |
| `@refine 0 10` | 身上裝備全部 +10 |
| `@go 0` | 回普隆德拉 |
| `@jumpto 名字` | 傳送到朋友身邊 |
| `@who` / `@where 名字` | 看誰在線上、在哪 |

競技場死掉不會扣經驗，1.5 秒後自動在普隆德拉復活補滿。
想改 NPC 或可用的指令：改 `pvp/pvp.txt`、`pvp/groups.yml`，再 `./ro.sh restart`（不用重新編譯）。
不想要 PvP 模式：`.env` 裡 `PVP_MODE=no`。

## 跟朋友一起玩

**同一個 Wi-Fi：**

1. 查這台 Mac 的區網 IP：系統設定 → Wi-Fi → 詳細資訊（例如 `192.168.1.20`）
2. 改 `.env`：`PUBLIC_IP=192.168.1.20`、`BIND_ADDR=0.0.0.0`，再 `./ro.sh restart`
3. 朋友用瀏覽器開 `http://192.168.1.20:3338`

**不在同一個地方：** 大家裝 [Tailscale](https://tailscale.com)（免費），把上面的 IP 換成你 Mac 的 Tailscale IP（`100.x.x.x`）。不建議直接把埠開放到網際網路上。

網頁版只需要 `3338` 這一個埠，素材也是從你的 Mac 傳過去，朋友什麼都不用裝。

## 想要更古早的介面

`.env` 裡的 `PACKETVER` 是客戶端日期，roBrowser 會顯示那個時期的介面：

| PACKETVER | 大約是 |
|---|---|
| `20130618`（預設） | 2013 年，經典介面，功能最完整 |
| `20100730` | 2010 年，更舊的介面（部分功能可能還沒做好） |

改完執行 `./ro.sh rebuild`。`PRERE=yes` 是經典版（復興前）規則，`no` 是復興後。

## 常用指令

| 指令 | 做什麼 |
|---|---|
| `./ro.sh start` / `stop` / `restart` | 開／關／重開 |
| `./ro.sh open` | 用瀏覽器打開遊戲 |
| `./ro.sh status` | 看哪些服務在跑 |
| `./ro.sh logs [login\|char\|map\|web]` | 看輸出 |
| `./ro.sh account <帳號> <密碼> [M\|F]` | 建帳號 |
| `./ro.sh gm <帳號> [等級]` | 設 GM（99 最高） |
| `./ro.sh sql` | 直接進資料庫 |
| `./ro.sh rebuild` | 改了 `PACKETVER` / `PRERE` 後重新編譯 |
| `./ro.sh reset` | 刪除所有帳號角色重來 |

## 常見問題

- **網頁一直轉圈、畫面是黑的**：`./ro.sh logs web` 看看是不是找不到 `.grf`，或 `.grf` 是加密版。
- **文字變亂碼**：繁中素材把 `.env` 的 `LANGTYPE` 改成 `14`，再 `./ro.sh restart`。
- **朋友連得到網頁但登入失敗**：確認 `.env` 的 `BIND_ADDR=0.0.0.0`，而且朋友開的網址就是 `PUBLIC_IP`。
- **想用 Windows 版原版客戶端**：也可以，連 `127.0.0.1:6900`，客戶端 exe 日期要跟 `PACKETVER` 一樣。
