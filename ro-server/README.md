# 自架 RO 伺服器（Mac 版）

用開源的 [rAthena](https://github.com/rathena/rathena) 在自己的 Mac 上跑一個 RO 伺服器，客戶端用 CrossOver（Wine）開，還可以加進 Steam 收藏庫，從 Steam 啟動。

> 只適合自己或朋友在區網玩、學習用。RO 的客戶端和素材版權屬於 Gravity，請不要公開架站營利或散布客戶端。

```
Mac
├─ Docker（OrbStack / Docker Desktop）
│   ├─ db      MariaDB 資料庫
│   ├─ login   :6900
│   ├─ char    :6121
│   └─ map     :5121
└─ CrossOver → Ragexe.exe → 連 127.0.0.1:6900
```

## 需要準備

| 東西 | 說明 |
|---|---|
| [OrbStack](https://orbstack.dev)（推薦）或 Docker Desktop | 跑伺服器。Apple Silicon 和 Intel 都可以 |
| [CrossOver](https://www.codeweavers.com/crossover) | 在 Mac 上跑 Windows 版客戶端（有 14 天試用）。免費的替代方案：Wine / Kegworks |
| 客戶端 | 從論壇下載的完整客戶端（data.grf 等素材）**加上一個已經修改過的 exe**，exe 的日期要跟 `PACKETVER` 一樣 |

### 客戶端要注意的地方
- 預設 `PACKETVER=20211103`，就是去找 **2021-11-03 的客戶端 exe**（rAthena 論壇最常見的版本）。用別的日期就改 `.env` 裡的 `PACKETVER`，再 `./ro.sh rebuild`。
- exe 要先用 WARP 或 NEMO 改過，至少要有：「讀取 clientinfo」、「不要求 1rag1 參數」、「關閉 Gravity 官方登入器檢查」。論壇大多直接提供改好的 exe。
- 把 `client/clientinfo.xml` 複製到客戶端的 `data/` 資料夾（也複製一份叫 `sclientinfo.xml`）。

## 第一次安裝

```bash
cd ro-server
./ro.sh setup      # 產生 .env，裡面有隨機密碼
./ro.sh start      # 第一次會編譯 rAthena，大約 5–15 分鐘
./ro.sh logs map   # 看到 "Server is ready" 就可以了，Ctrl+C 離開
./ro.sh account myname mypass   # 建立帳號
./ro.sh gm myname               # （選用）設成 GM
```

不想用指令建帳號的話，也可以在遊戲登入畫面輸入 `帳號_M`（男）或 `帳號_F`（女）加密碼，就會自動註冊。

## 在 Mac 上開客戶端

1. 打開 CrossOver → 「新增容器」，選 **Windows 10 64-bit**，取名 `RO`。
2. 把整個客戶端資料夾複製進容器的 `drive_c`（CrossOver → 容器 → 開啟 C: 槽）。
3. 在 CrossOver 裡對容器安裝元件：**DirectX for Modern Games** 和 **Visual C++ 2015–2022 Redistributable**。
4. 雙擊 `Ragexe.exe`（或你的 exe 名稱）測試能不能登入。

## 加進 Steam（當成 Mac 版的 Steam 遊戲）

```bash
./ro.sh launcher "$HOME/Library/Application Support/CrossOver/Bottles/RO/drive_c/RO/Ragexe.exe" RO
```

這會產生 `~/Applications/MyRO.app`，點它會先自動開伺服器，再用 CrossOver 開客戶端。
接著在 Steam：**遊戲 → 新增非 Steam 遊戲到我的收藏庫 → 瀏覽**，選 `MyRO.app`，就能從 Steam 啟動、用 Steam 手把設定了。

## 跟朋友一起玩（同一個 Wi-Fi）

1. 查這台 Mac 的區網 IP：系統設定 → Wi-Fi → 詳細資訊（例如 `192.168.1.20`）。
2. 改 `.env`：`PUBLIC_IP=192.168.1.20`、`BIND_ADDR=0.0.0.0`，然後 `./ro.sh restart`。
3. 每個人客戶端的 `clientinfo.xml` 裡的 `<address>` 都改成 `192.168.1.20`。

> 不建議直接開放到網際網路。要遠端一起玩，可以用 Tailscale 之類的虛擬區網，把 `PUBLIC_IP` 設成 Tailscale 的 IP。

## 常用指令

| 指令 | 做什麼 |
|---|---|
| `./ro.sh start` / `stop` / `restart` | 開／關／重開伺服器 |
| `./ro.sh status` | 看哪些伺服器在跑 |
| `./ro.sh logs [login\|char\|map]` | 看伺服器輸出 |
| `./ro.sh account <帳號> <密碼> [M\|F]` | 建帳號 |
| `./ro.sh gm <帳號> [等級]` | 設 GM（99 最高） |
| `./ro.sh sql` | 直接進資料庫 |
| `./ro.sh rebuild` | 改了 `PACKETVER` 後重新編譯 |
| `./ro.sh reset` | 刪掉所有資料重來 |

## 自訂伺服器

經驗倍率、掉寶率等設定在 rAthena 的 `conf/battle/*.conf`。最簡單的改法：

```bash
docker compose exec map sh -c 'echo "base_exp_rate: 1000" >> conf/import/battle_conf.txt'   # 經驗 10 倍
docker compose restart map
```

（容器重建後會還原，想永久保留可以把設定寫進 `docker/Dockerfile`。）

## 常見問題

- **登入時卡住／斷線**：九成是 exe 日期跟 `PACKETVER` 不一致。
- **選完伺服器就斷線**：`PUBLIC_IP` 不是客戶端連得到的 IP。
- **畫面黑屏或閃退**：CrossOver 容器沒裝 DirectX / VC++，或客戶端的 `setup.exe` 先跑一次選解析度、關掉全螢幕。
- **中文亂碼**：客戶端要用繁中（twRO）版本的 data，`langtype` 改成 `14`。
