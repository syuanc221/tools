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
| `schema.sql` | Supabase 資料表與存取權限（已套用，重建專案時才需要再跑） |
| `audio/*.m4a` | 背景音樂（遊戲用相對路徑 `audio/…` 讀取） |
| `icon.svg`、`icon-32.png`、`icon-192.png`、`icon-512.png`、`apple-touch-icon.png` | 網站 icon「帽橋巫師」（帽簷是拱橋、拱下兩顆眼睛）；iPhone 用的 180 px 是不帶圓角的滿版 |
| `og.png` | 分享預覽圖 1200×630（`build.py` 寫入 og:image／twitter:image） |
| `brand/` | icon 與分享圖的原始檔：`icon-a.svg`、滿版 `icon-a-square.svg`、黑白版 `icon-a-mono.svg`、`share.html`（用 Chrome headless 截圖產生 `og.png`） |

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

- 100 張各不相同的卡（`src/game.html` 的 `CARD_LIST`），分屬 7 元素（火焰、冰霜、雷霆、暗影、聖光、森林、符文）。每張有自己的 3D 造型（由 `m:` 配方組成）與特殊能力（`x:`：護盾、治療光環、狂暴、減速、召喚、倒下爆炸／召喚、衝鋒、連鎖閃電、自爆、吸血）；召喚物定義在 `TOKEN_LIST`
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
- 戰鬥血條：所有單位常駐顯示、受傷時白色殘影、血量低於 30% 閃紅，塔上顯示血量數字
- 冒險三章劇情、天梯、寶箱、抽卡（50 抽保底）、卡牌升級、公會與聊天、好友即時對戰（房主模擬、對手看鏡像）
- 3D 用 Three.js r128，卡圖與頭像都是即時從 3D 模型渲染；圖示全部是 SVG，不用 emoji；字體 Noto Sans TC 黑體；Poly 扁平風格
- 音效用 Web Audio 即時合成；背景音樂是 `audio/` 裡的音檔
