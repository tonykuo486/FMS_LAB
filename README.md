# FMS_LAB — 工廠管理系統教學實驗室

> 教育訓練專案（2026-08）。**同一份需求規格，兩個世代的實作**：
> 學員用同一套功能需求（FACT/TASK/PERS/ACC 編號完全相同）分別以
> 伺服端渲染（V2）與 TypeScript 全棧（V3）完成一套「多據點生產任務排程系統」。
> 全程**離線可用、禁用 CDN**（教室無網路也能開課與驗收）。

---

## 目錄結構

```
FMS_LAB/
├── README.md                 ← 本檔（入口導覽）
├── .gitignore
├── docs/
│   └── V2_V3_對照表.md       ← 兩版完整對照（講師備課/學員課後對讀）
├── FMS_V2/                   ← V2 教材（Python 路線）
│   ├── README.md             ← 開工指引＋轉交自己 GitHub 的步驟
│   ├── .gitignore            ← Python/Django/uv 適用（★不擋 static/lib/ 離線資產）
│   └── docs/
│       ├── SRS.md            ← 需求規格書 v3.0（做什麼）＋狀態圖／時序圖
│       ├── SDD.md            ← 軟體設計文件 v1.0（怎麼做）＋ER 圖
│       └── GUIDE.md          ← 課程指引 v1.0（怎麼學：里程碑／踩坑地圖）
└── FMS_V3/                   ← V3 教材（TypeScript 路線；原獨立 repo，已併入本 repo）
    ├── README.md             ← 開工指引＋轉交自己 GitHub 的步驟
    ├── .gitignore
    ├── infra/                ← 開發期環境（PG 17 + MinIO），2026-08-25 實測可用
    └── docs/
        ├── SRS.md            ← 需求規格書 v4.0（做什麼）＋狀態圖／時序圖
        ├── SDD.md            ← 軟體設計文件 v1.0（怎麼做）＋ER 圖
        └── GUIDE.md          ← 課程指引 v1.0（怎麼學：里程碑／踩坑地圖）
```

## 兩個版本一眼看

| | **V2** | **V3** |
|---|---|---|
| 路線 | 約定優於配置（伺服端渲染） | 顯式契約（型別安全全棧） |
| 棧 | Python 3 / Django / SQLite / AdminLTE | TypeScript / Bun / Elysia / PostgreSQL 17 / Refine + Ant Design |
| 版本 | uv 管理（[V2 SDD §2](FMS_V2/docs/SDD.md)） | **鎖定表 [V3 SDD §11](FMS_V3/docs/SDD.md)**（2026-08-25 實測核實） |
| 適合 | 第一個 Web 專案的初學者 | 已懂 HTTP/SQL，要學前後端分離 |
| 規格 | [SRS](FMS_V2/docs/SRS.md)／[SDD](FMS_V2/docs/SDD.md)／[GUIDE](FMS_V2/docs/GUIDE.md) | [SRS](FMS_V3/docs/SRS.md)／[SDD](FMS_V3/docs/SDD.md)／[GUIDE](FMS_V3/docs/GUIDE.md) |

功能需求兩版**一字不差**（編號相同）；差異全在實作層——詳見
[docs/V2_V3_對照表.md](docs/V2_V3_對照表.md)。

> **兩版都採 SRS／SDD／GUIDE 三份文件結構**（需求／設計／教學分離）。
> **SRS 兩版幾乎等長**（V2 271 行、V3 273 行）——因為需求相同；
> **SDD 差距懸殊**（V2 157 行、V3 644 行）——因為 Django「約定優於配置」把大量
> 設計決策內建了，V3 走顯式契約路線每層都要自己接。**這個厚度差距本身就是教材**。

## 專案題目（30 秒版）

工廠在多個生產據點之間排程生產任務：操作員按「據點×週次」登記；據點主管把
「產品＋製程」組成任務，指派給**持有對應證照的操作員**與**具備對應能力的工作站**，
系統須擋下所有排程衝突（時段重疊、時窗外、超時）；任務走
In Planning → Scheduled → Finished 三態；匿名訪客可看公開看板（操作員姓名匿名化）。

## 怎麼用這套教材

**講師**：
1. 先讀 [docs/V2_V3_對照表.md](docs/V2_V3_對照表.md)（§4 核心需求逐條對照＝授課主軸）。
2. 選版開課（初階 V2 / 進階 V3，或 V2→V3 連開）。
3. 開課前照各版 SRS 的 **TECH-12/TECH-13** 準備離線環境（V2：wheelhouse＋`static/lib/`
   資產包；V3：bun offline 快取；**兩版共通**：Docker Desktop＋基底映像 `docker save` 預載包），
   每台機器**斷網 smoke test** 一遍（含 `docker compose up --build`）。
4. 進度照 **GUIDE.md §1 里程碑（M1~M6）**；驗收照 **SRS.md 附錄 Demo 劇本**（兩版同一份，10 分鐘走位）。

**學員**：
0. **先讀你那版的 README**（[V2](FMS_V2/README.md) ／ [V3](FMS_V3/README.md)）——
   工具鏈確認、指令速查，以及**把作業轉交到你自己 GitHub** 的完整步驟都在那。
1. 精讀你那版的 `docs/SRS.md` 第 2 章——**每一條編號都是驗收項**。
2. 開工前先讀 **GUIDE.md §2 踩坑地圖**（ISO 第 53 週、排程 race、CSV 編碼是必撞的三個）。
3. 依 M1~M6 交付，commit 歷史要看得出里程碑節奏（最後一天一包 zip 直接扣分）。
4. 自測用附錄 C 劇本走一遍——老師抽查用的是同一份。

## 四條不變的鐵律（兩版通用，驗收必查）

1. **後端守衛才是安全**——前端/模板擋掉按鈕不算數，每個端點都要有自己的權限檢查。
2. **資料庫約束才是底**——排程衝突的應用層檢查有 race，unique/exclude 約束保底。
3. **完全離線**——斷網展示全部功能，DevTools Network 零外部請求（ACC-6）。
4. **交付即 Compose**——開發期隨你 dev server，驗收一律 `docker compose up -d` 三步啟動
   （ACC-7），且 `down`/`up` 後資料仍在（volume 驗證）。

---

## 附：GitHub 上傳與認證程序（2026-08-25 實測核實）

本 repo 就是照以下步驟上傳的——**每一步都實際走過**。學員交付自己的作業 repo 時照抄，
把帳號換成自己的即可。

### 1. 裝 GitHub CLI（一次性）

```powershell
winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
gh --version    # 實測：2.98.0
```

### 2. 認證（一次性；唯一需要開瀏覽器的步驟）

```powershell
gh auth login --hostname github.com --git-protocol https --web
```
- 終端機會顯示**一次性代碼**（例：`XXXX-XXXX`）→ 開 https://github.com/login/device
  → 輸入代碼 → Authorize。
- 驗證：`gh auth status` 顯示 `✓ Logged in to github.com account <你的帳號>`。
- token 存在本機 keyring——之後 push/建 repo 都不再問密碼。

### 3. 本地 repo 準備（注意兩個坑）

```bash
cd <你的專案>
git init -b main
git config user.email "<帳號>@users.noreply.github.com"   # ★坑1：公開 repo 別用私人/公司信箱
git config user.name  "<帳號>"
# ★坑2：先寫 .gitignore 再 add——node_modules/data/.env/dist 進了歷史就很難清
git add -A && git commit -m "docs: 初版"
```

### 4. 建遠端 repo 並推送

```bash
gh repo create <帳號>/<repo名> --private --source . --remote origin --push
```
- 一條指令＝建 repo＋設 remote＋push。作業一律先 `--private`，要公開再：
  `gh repo edit --visibility public`。
- 若 repo 已在網頁上建過，會回 `Name already exists`——改用
  `git remote add origin https://github.com/<帳號>/<repo名>.git && git push -u origin main`。
- 在網頁建 repo 時**不要勾**任何初始化選項（README/.gitignore/license），
  否則遠端多出無關 commit，第一次 push 會被拒。

### 5. 核實（推完必做，不是「看起來成功」而是「驗過一致」）

```bash
git ls-remote origin main     # 遠端 commit hash
git log --oneline -1          # 本地 commit hash——兩者必須相同
gh repo view --json visibility,url,defaultBranchRef
```
本 repo 實測：遠端 main＝本地 main＝同一 hash、visibility=PRIVATE、分支 main——三項全對才算完成。

> 上傳前最後一關：`grep` 全 repo 掃一遍**不該公開的字串**（公司網域/內網 IP/帳密/客戶名）
> ——本 repo 上傳前實掃＝零殘留。這一步養成習慣，比事後刪 commit 便宜一萬倍。

---

*文件維護約定：需求或技術棧變動時，同步三處——兩版 `SRS.md` ＋ `docs/V2_V3_對照表.md`。*
