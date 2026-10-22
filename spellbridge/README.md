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
- 冒險三章劇情、天梯、寶箱、抽卡（50 抽保底）、卡牌升級、公會與聊天、好友即時對戰（房主模擬、對手看鏡像）
- 3D 用 Three.js r128，卡圖與頭像都是即時從 3D 模型渲染；圖示全部是 SVG，不用 emoji；字體 Noto Sans TC 黑體；Poly 扁平風格
- 音效用 Web Audio 即時合成，沒有音檔
