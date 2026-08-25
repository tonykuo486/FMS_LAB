# FMS_V3 — 工廠管理系統（TypeScript 全棧路線）

> **這是一份需求規格，不是一份可執行的專案。**
> 目錄裡沒有任何實作程式碼——`backend/`、`frontend/`、`schema.sql`、`Dockerfile`
> 全部由**你**依 [`docs/SRS.md`](docs/SRS.md) 產出。這就是本次專題的作業內容。

**技術棧**：TypeScript 5.9.3／Bun 1.4.0／Elysia 1.4.29／**PostgreSQL 17**／React 18 + Refine + antd 5.29.3／Vite 6
（**完整鎖定版本見 [`docs/SRS.md`](docs/SRS.md) 2.1.11——2026-08-25 實測核實**）
**必讀**：[`docs/SRS.md`](docs/SRS.md)——第 2 章**每一條編號都是驗收項**。

---

## 開工前三件事

**1. 精讀 SRS 第 2 章。** 除了功能需求，這四節是硬規格，不是建議：

| 節 | 內容 | 為何不能略過 |
|---|---|---|
| 2.1.3 | 專案結構（monorepo） | 目錄長什麼樣是驗收項，不是品味問題 |
| 2.1.4 | 權限矩陣（RBAC） | 前端擋 UX、**後端擋安全**——兩邊都要 |
| 2.1.7 | SQL 資產化規範 | 每條 SQL 要有 `source:` 反查需求編號 |
| 2.1.8 | UI 設計規範（Steel Blue） | 色票寫死在 `theme.ts`，禁散寫 |

**2. 先讀附錄 B 踩坑地圖。** 共通三坑（ISO 第 53 週／排程 race／CSV 編碼）之外，
TS 全棧還有四個專屬坑——**cookie 跨埠**（坑 7）幾乎每個人都會撞：
vite 5173 → 後端 3000，cookie 要走 vite proxy 同源化才收得到。

**3. 確認工具鏈。**

```bash
bun --version        # 需 Bun 1.4.0（版本鎖定表見 SRS 2.1.11）
docker --version     # 資料庫走 Docker,開發期就會用到（TECH-4/13）
```

**資料庫不需要在本機安裝。** repo 已附 [`docker-compose.yml`](docker-compose.yml)
（起手包：PostgreSQL 17 + pgvector、MinIO），三步就有環境：

```bash
cp .env.example .env          # ★把裡面的密碼全部改掉
docker compose up -d          # 起 db + minio
docker compose ps             # 兩個都 healthy 才算好
```

接著建測試用資料庫（SRS 2.1.6：測試禁連正式庫），這步只做一次：

```bash
docker compose exec db createdb -U fms fms_test
```

之後開發時的啟動順序：

```bash
docker compose up -d                           # ①基礎服務
cd backend  && bun run --watch src/index.ts    # ②後端
cd frontend && bun run dev                     # ③前端
```

| 服務 | 位址 | 用途 |
|---|---|---|
| PostgreSQL | `localhost:5432` | 資料庫（可用 psql／DBeaver 連進去看） |
| MinIO 主控台 | http://localhost:9001 | 物件儲存管理介面 |
| MinIO S3 API | `localhost:9000` | **本次作業用不到**，將來 ETL／檔案上傳用 |

> ⚠ 這份 compose 只有**基礎服務**。SRS 2.1.9 要求的交付形態是**三服務**
> （加上 backend / frontend），ACC-7 驗收跑的是那一份——要自己補完。

> **MinIO 現在可以不管它。** 放進起手包是因為將來要做 CSV 原始檔留存、報表匯出、
> ETL 中繼檔時直接可用，而 S3 API 是業界標準（換到 AWS S3 是同一套 SDK）。
> 嫌它佔資源就 `docker compose up -d db` 只起資料庫。

沒有 Bun 就先裝：

```powershell
# Windows (PowerShell)
powershell -c "irm bun.sh/install.ps1 | iex"
```
```bash
# macOS / Linux
curl -fsSL https://bun.sh/install | bash
```

## Bun 速查（TECH-1：一把抓，免 Node+npm+jest 三件套）

| 你要做的事 | 指令 |
|---|---|
| 開專案 | `bun init` |
| 加依賴 | `bun add elysia@1.4.29 pg@8.23.0`（**一律寫死版本,見 SRS 2.1.11**） |
| 加開發依賴 | `bun add -d typescript @biomejs/biome` |
| 還原環境（照 `bun.lock`） | `bun install` |
| 離線還原（教室機，TECH-12） | `bun install --offline` |
| 後端 dev（熱重載） | `bun run --watch src/index.ts` |
| 前端 dev | `bun run dev`（Vite） |
| 測試（TECH-8） | `bun test` |
| 型別檢查（CI 三綠燈之一） | `bunx tsc --noEmit` |

> **`bun.lock` 要進版控。** 它是「環境可重現」的唯一真相——助教在自己機器上
> `bun install` 必須還原出和你一模一樣的版本，否則「在我電腦上會動」不算數。

## ⚠ 開工第一件事：版本寫死，別打 `bun add <套件>`

`bun add antd` 會裝到 **antd 6**，但 `@refinedev/antd` 要的是 **antd 5**——
**Bun 不會報錯，而且它還 render 得出來**，看起來一切正常，直到某個元件莫名炸掉。

照 [`docs/SRS.md`](docs/SRS.md) **2.1.11 版本鎖定表**把 `package.json` 一次寫好
（**不加 `^`**），再 `bun install`。那張表是 2026-08-25 實際裝起來、跑過測試、
`tsc` 過、`vite build` 過的組合。

## 兩個最容易被扣分的地方

**匿名化的位置（PERS-24）。** 在前端藏名字＝**沒藏**——API 回應裡看得到。
必須在 **SQL 層**就以別名輸出（見 SRS 2.1.7 的 `dense_rank()` 範例），
API 從頭到尾不含真名。

**連線池與測試隔離（2.1.5／2.1.6）。** 後端一律用 `db/pool.ts` 的連線池單例，
**禁止**每個請求開新連線（會 `too many connections`）。測試**禁連正式庫**——
用 `fms_test` 資料庫，每個測試檔開自己的 schema，跑完 `DROP SCHEMA … CASCADE`。

**排程 race 是必測項（2.1.5）。** 換成真 PG 之後，兩條連線同時搶同一工作站同一時段
**真的重現得出來**：服務層檢查會雙雙通過，`EXCLUDE USING gist` 約束會擋下其中一條
（`23P01`）。請寫一個並行測試證明它——這是本課「應用層檢查會有 race，
資料庫約束才是底」從口號變成你親手驗過的事實。

## 交付門檻（照這個順序自測）

1. **附錄 A 里程碑 M1~M6** 逐項完成——commit 歷史要看得出節奏（最後一天一包 zip 直接扣分）。
2. **附錄 C Demo 劇本**自己走一遍——老師抽查用的是同一份，10 分鐘走位。
3. **CI 三綠燈**：`bun install` → `tsc --noEmit` → `bun test` 全綠。
4. **ACC-6 斷網驗收**：拔網路線／關 Wi-Fi，全功能仍可展示，DevTools Network 零外部請求。
5. **ACC-7 Compose 驗收**：`docker compose up -d` 三步啟動；`down` 再 `up` 後**資料仍在**。

---

## 轉交：推到你自己的 GitHub

本目錄目前是教材 repo（`FMS_LAB`）的一部分。你的作業要有**自己的 repo、自己的 commit
歷史**，所以第一步是把 V3 抽成獨立專案，而不是在教材 repo 上開分支。

### 步驟 1：抽出成獨立專案

```bash
# 在 FMS_LAB 之外的位置（例如 ~/projects）
mkdir fms-v3 && cd fms-v3
cp -r /path/to/FMS_LAB/FMS_V3/. .     # Windows PowerShell: Copy-Item -Recurse ...\FMS_V3\* .
```

複製過來的有 `README.md`、`.gitignore`、`docker-compose.yml`、`.env.example`
與 `docs/SRS.md`——**沒有任何程式碼是正常的**，其餘全部是你要寫的。

> ★複製後**確認 `.env` 沒有跟著過來**（它不該存在於教材 repo，但你本機跑過就會有）：
> `ls -a | grep '^\.env$'` 有輸出就先刪掉，等 git init 完再重建。

### 步驟 2：git init（**注意兩個坑**）

```bash
git init -b main

# ★坑1：公開 repo 別用私人/公司信箱——用 GitHub noreply 信箱
git config user.email "<你的帳號>@users.noreply.github.com"
git config user.name  "<你的帳號>"

# ★坑2：先確認 .gitignore 再 add
#   node_modules/、data/ 進了歷史就很難清——本目錄已附一份,開工前再確認一次
cat .gitignore

git add -A && git commit -m "chore: 專案初始化（SRS + README + gitignore）"
```

> `bun.lock` **要**進版控（環境可重現）；`node_modules/` **不進**（可重建、體積大）。
> **`.env` 絕對不進版控**（含資料庫密碼）——repo 只放 `.env.example`。
> PG 資料在 Docker 具名 volume 裡，本來就不在專案目錄下。

### 步驟 3：建遠端 repo 並推送

```bash
gh repo create <你的帳號>/fms-v3 --private --source . --remote origin --push
```

一條指令＝建 repo＋設 remote＋push。作業一律先 `--private`；要給老師看再加協作者，
或 `gh repo edit --visibility public`。

沒裝 GitHub CLI 或還沒認證，見教材根目錄 [`../README.md`](../README.md) 的
「附：GitHub 上傳與認證程序」——那一節每一步都實測過。

### 步驟 4：核實（推完必做）

**不是「看起來成功」，而是「驗過一致」**：

```bash
git ls-remote origin main     # 遠端 commit hash
git log --oneline -1          # 本地 commit hash —— 兩者必須相同
gh repo view --json visibility,url,defaultBranchRef
```

> **上傳前最後一關**：`grep` 全 repo 掃一遍不該公開的字串（公司網域／內網 IP／
> 帳密／客戶名／JWT secret）。這一步養成習慣，比事後刪 commit 便宜一萬倍。

---

*需求有疑義以 [`docs/SRS.md`](docs/SRS.md) 為準；SRS 與本檔衝突時，以 SRS 為準。*
