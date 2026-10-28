# 秘法雙橋 SPELLBRIDGE

3D 巫師卡牌塔防對戰。正式網址：https://spellbridge.off-office.co

## 檔案

| 路徑 | 內容 |
|---|---|
| `src/game.html` | 遊戲本體原始碼（要改遊戲就改這個）。同一份也發布在 claude.ai Artifact：https://claude.ai/artifact/WUXs7nFGHTjBZsfeTtgAH2 |
| `src/shim.js` | 獨立網站用的後端轉接層：把遊戲的 `claude.use('db' / 'user' / 'room')` 對應到 Supabase（登入、資料表、即時頻道） |
| `src/config.json` | Supabase 專案網址和公開 anon key（本來就是公開用的，不是密碼） |
| `src/build.py` | 把 `game.html` + `shim.js` + 設定打包成上一層的 `index.html` |
| `index.html` | 打包結果，GitHub Pages 直接提供這個檔案 |
| `schema.sql` | Supabase 資料表與存取權限（已套用，重建專案時才需要再跑）；含 events／reports／admins 與後台函式 |
| `audio/*.m4a` | 背景音樂（遊戲用相對路徑 `audio/…` 讀取） |
| `icon.svg`、`icon-32.png`、`icon-192.png`、`icon-512.png`、`apple-touch-icon.png` | 網站 icon「符文晶柱」（深色框裡的紫色晶柱、金色符文線、左邊一根小晶柱）；iPhone 用的 180 px 是不帶圓角的滿版 |
| `og.png` | 分享預覽圖 1200×630（`build.py` 寫入 og:image／twitter:image） |
| `brand/` | icon 與分享圖原始檔：`icon-shard.svg`（現用）、滿版 `icon-shard-square.svg`、`share.html`（戰場版分享圖，用 Chrome headless 截圖產生 `og.png`）、`card-back.svg`；`options/` 是其他提案 |

## 改遊戲的流程

1. 修改 `src/game.html`（或 `src/shim.js`）
2. `cd spellbridge/src && python3 build.py`
3. commit 並 push 到 `main`
4. GitHub Pages 約 1 分鐘內更新，正式網址自動跟著變（不用動 Vercel）

## 網站架構

- **網域**：`spellbridge.off-office.co`，DNS 在 Cloudflare（CNAME → `cname.vercel-dns.com`，DNS only）
- **Vercel 專案** `spellbridge`（Yoona's projects）：只有一個 `vercel.json`，把所有路徑轉接到 `https://syuanc221.github.io/tools/spellbridge/`。Vercel 沒有連 GitHub，也不需要重新部署
- **Supabase 專案** `spellbridge`（yoona-studio's Org，東京，ref `kenzsxyyqhfijbkeqnjz`）
  - 一張 `public.docs` 表（path / coll / id / owner / data），RLS：players、guilds、chat 大家可讀；每個人只能寫自己的 `players/<uid>`、`guilds/<uid>`、`chat/<uid>`、`data/users/<uid>/…`
  - Realtime：資料表變更（公會、排行榜、聊天）與即時頻道（好友對戰房間 `room-duel-XXXX`）
  - Google 登入：沿用市長大人的 Google OAuth 用戶端（Google Cloud 專案 mayor-island），Supabase callback `https://kenzsxyyqhfijbkeqnjz.supabase.co/auth/v1/callback`

## 遊戲內容（摘要）

- 116 張各不相同的卡（`src/game.html` 的 `CARD_LIST`；最後 16 張是妖精、吸血鬼、狼人、女巫系列，新能力 `frenzy` 重傷狂化），分屬 7 元素（火焰、冰霜、雷霆、暗影、聖光、森林、符文）。每張有自己的 3D 造型（由 `m:` 配方組成）與特殊能力（`x:`：護盾、治療光環、狂暴、減速、召喚、倒下爆炸／召喚、衝鋒、連鎖閃電、自爆、吸血）；召喚物定義在 `TOKEN_LIST`
- 舊版「兵種 × 元素」卡在讀檔時自動換成金幣補償（`fixSave`）
- 卡牌升級：Lv.1～10，所需複本依稀有度不同（`NEEDS`），金幣 `COST`；Lv.4／7／10 各得一顆星（+5% 數值並強化特殊能力，`mechFor`／`spellFor`）；滿級後多餘複本可換金幣；有全部升級與升級動畫
- 音效：Web Audio 即時合成，各兵種有不同出場聲、各能力有專屬音效
- 背景音樂：`audio/` 裡 5 首 Suno 曲子（Suno Pro，可商用；原檔轉成 96 kbps AAC）：主選單 `main-theme`、一般戰鬥 `battle`、第三章魔王戰 `dragon-boss`、冒險章節選單與劇情對話 `adventure-map`、卡牌／抽卡／公會／個人頁 `guild-hall`。切換畫面時約 2 秒交叉淡入淡出，第一次點擊後才開始播放，設定頁可關閉並調整音量。音檔讀不到時（例如 claude.ai Artifact 版本）會自動改回 Web Audio 合成的 `BGM` 迴圈
- 卡框：所有卡都是同一種直角矩形；元素決定底色與底紋，稀有度決定外框
- 排行榜：首頁「排行榜」按鈕（`#rankOv`），巫師前 50 名（自己的名次固定在底部）與公會總獎盃排名
- 抽卡／寶箱開場：祭壇法陣旋轉、寶箱越晃越大力，閃光顏色是這次最高稀有度，卡牌依序飛入（`reveal`／`revealDeal`），點一下可跳過
- 對手出牌：地上紅圈＋卡名標籤，戰場左上角列出最近 3 張（`enemyPlayed`；好友對戰只有房主看得到）。鏡頭 FOV 24、較俯視，遠端不再被壓扁
- 卡背：`brand/card-back.svg`（菱格、金框、帽橋巫師印章），以 data URI 寫在 `.rcard .b`
- Google 廣告：首頁底部 `#adHome`、戰鬥結算 `#adEnd` 各一條 100px 橫幅（不放在戰鬥中或抽卡揭曉）。AdSense 帳號同市長大人／貓指名俱樂部（ca-pub-3250433705379365，單元暫用 8844785341），只在 *.off-office.co 載入；`?adtest=1` 顯示測試框。`ads.txt` 在本資料夾
- 戰鬥鏡頭的霧跟著鏡頭距離往後推（`fitCamera`），不然窄鏡頭退得遠會讓整個場地變暗
- 倒數音效：剩 1 分鐘鐘聲＋號角（`lastMin`）、最後 10 秒逐秒升高的嗶聲（`count`，最後 3 秒較重）、延長賽號角（`overtime`），由 `timeCues` 觸發，好友對戰兩邊都會響；最後一分鐘與延長賽時 Suno 戰鬥曲加速到 1.08 倍
- 埋點：`shim.js` 的 `TRACK` 每 8 秒批次寫入 `public.events`（session、screen、battle_start/end、gacha、chest、upgrade、ad、error、report），帶裝置 id、session id 與版本號（`build.py` 產生的 `SB_VER`）
- 問題回報：個人頁「設定 → 回報問題」，寫入 `public.reports`，自動附上版本、畫面、裝置、最近錯誤
- 後台：`admin.html`（由 `src/admin.html` 產生），先在遊戲裡用管理員 Google 帳號登入再打開；資料來自 `admin_stats()` 與 `reports`，只有 `public.admins` 裡的帳號讀得到。本機可用 `admin.html?demo=1` 看範例
- 戰鬥血條：所有單位常駐顯示、受傷時白色殘影、血量低於 30% 閃紅，塔上顯示血量數字
- 冒險三章劇情、天梯、寶箱、抽卡（50 抽保底）、卡牌升級、公會與聊天、好友即時對戰（房主模擬、對手看鏡像）
- 3D 用 Three.js r128，卡圖與頭像都是即時從 3D 模型渲染；圖示全部是 SVG，不用 emoji；字體 Noto Sans TC 黑體；Poly 扁平風格
- 音效用 Web Audio 即時合成；背景音樂是 `audio/` 裡的音檔

## 平衡模擬

`balance/` 用遊戲本身的引擎跑數值檢查（不畫畫面，約 3 秒）：每張非法術卡和其他所有卡單挑一次，再測 25 秒內對一座塔造成的傷害。

1. 用任何靜態伺服器提供遊戲（例如在 `spellbridge/` 執行 `python3 -m http.server 8766`，three.js 要能載入）
2. `SB_URL=http://localhost:8766/ node balance/run.mjs out.json`（需要 Playwright）
3. `python3 balance/ana.py out.json`：依費用算出預期勝率，列出偏強（score 高）和偏弱的卡

只打建築的卡（巨像、野豬騎士）、治療和自爆類卡單挑勝率本來就低，看塔傷和實際用途判斷。飛行單位因為地面近戰打不到，單挑數字會偏高。

## 更新提示（跟 3D 市長大人同一套）

- `build.py` 每次打包都把建置時間寫進 `window.SB_VER`（例如 `20261028-0352`）
- 遊戲每分鐘（以及切回分頁時）用不快取的方式重抓 `index.html`，版本號不同就在畫面上方顯示「遊戲有新版本了！」，玩家自己按「更新」才重新整理；戰鬥中不顯示，回到選單才出現；按「稍後」同一版不再跳
- 更新後第一次開啟會顯示「更新內容」，內容來自 `game.html` 的 `CHANGELOG`。**每次發佈新功能請在 `CHANGELOG` 最前面加一筆**
- 個人頁「設定」有遊戲版本、更新內容、檢查更新

## Logo 與圖示

- 主檔是 `icon.svg`（方案 B1）：黑底圓角方形，白色幽靈巫師貼紙、黑色粗邊、紫→青→萊姆綠的彩虹外框，兩隻拱形小腳代表雙橋。遊戲首頁標題與載入畫面內嵌同一個圖形
- `icon-32.png`（分頁小圖示）、`apple-touch-icon.png`（180）、`icon-192.png`、`icon-512.png`、`og.png`（1200×630 分享預覽）都由它產生；`apple-touch-icon.png` 是不切圓角的版本（iOS 會自己裁圓角）

