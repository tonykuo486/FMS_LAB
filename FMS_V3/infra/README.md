# infra — 開發期基礎設施

> ✅ **2026-09-02 複驗通過**（infra/ 曾被刪除後加回，已重新核實 12 項全過——
> 含 PG 17.11、`EXCLUDE` 約束四情境、並行 race、`down`/`up` 保留、`db/init` 自動執行；
> 詳見本檔末「實測紀錄」）。
>
> ✅ **2026-08-25 首次實測**（Docker 29.5.3 / Compose v5.1.4 on WSL2 Ubuntu）：
> `docker compose up -d` → db 與 minio 皆 `healthy`、PostgreSQL 17.11、
> pgvector 0.8.6 與 btree_gist 1.7 皆可用、`down`/`up` 後資料保留、
> `db/init/` 自動執行、[SDD §5](../docs/SDD.md) 的 `EXCLUDE` 約束與並行 race 實測符合預期。
> 詳見本檔末「實測紀錄」。

**這個目錄不是你的交付物，是給你用的環境。**
裡面只有「開發時需要、但你不必自己寫」的外部服務：資料庫與物件儲存。

| 服務 | 內容 | 本次作業 |
|---|---|---|
| `db` | PostgreSQL 17 + pgvector | **必要**（SRS TECH-4／[SDD §5](../docs/SDD.md)） |
| `minio` | S3 相容物件儲存 | **用不到**，為將來 ETL／檔案上傳預留 |

## 起手（第一天就做這個）

```bash
cd infra
cp .env.example .env      # ★把裡面的密碼全部改掉
docker compose up -d
docker compose ps         # 兩個都 healthy 才算起好
```

建測試資料庫（[SDD §6](../docs/SDD.md)：測試禁連正式庫），**只做一次**：

```bash
docker compose exec db createdb -U fms fms_test
```

驗證連得上：

```bash
docker compose exec db psql -U fms -d fms -c "SELECT version();"
```

## 連線資訊

| 服務 | 從**宿主機**連（開發期） | 從**容器內**連 |
|---|---|---|
| PostgreSQL | `localhost:5432` | `db:5432` |
| MinIO S3 API | `localhost:9000` | `minio:9000` |
| MinIO 主控台 | http://localhost:9001 | — |

> 開發期你的後端是用 `bun run --watch` 跑在**宿主機**上，所以 `PGHOST=localhost`。
> 等你把 backend 也容器化（交付形態），才會變成 `PGHOST=db`。

## 用 DBeaver 連進資料庫（強烈建議）

用 GUI 直接看資料，比每次下 `psql` 快得多——**排程衝突的資料到底長什麼樣、
`EXCLUDE` 約束為什麼擋下你那筆**，看表比猜快。

> DBeaver Community Edition 是免費的：https://dbeaver.io/download/
> （教室離線環境請講師事先發安裝檔。）

### 連線設定

先確認資料庫起來了：`docker compose ps` → `db` 顯示 `healthy`。

DBeaver 選 **Database ▸ New Database Connection ▸ PostgreSQL**，填：

| 欄位 | 值 | 說明 |
|---|---|---|
| **Host** | `localhost` | ★不是 `db`——`db` 是容器內部的名字 |
| **Port** | `5432` | 若改過 `.env` 的 `POSTGRES_PORT` 就填你改的 |
| **Database** | `fms` | 測試庫則填 `fms_test` |
| **Username** | `fms` | `.env` 的 `POSTGRES_USER` |
| **Password** | 你在 `.env` 設的那組 | `POSTGRES_PASSWORD` |

按 **Test Connection** → 成功再按 Finish。

> **第一次連會問要不要下載 PostgreSQL 驅動** → 按下載（需網路，教室離線環境
> 請事先在有網路時連一次，驅動會留在本機）。

### 常見連不上的原因

| 症狀 | 原因與解法 |
|---|---|
| `Connection refused` | 資料庫沒起來或還沒 ready。`docker compose ps` 看是不是 `healthy`（`starting` 不算） |
| `password authentication failed` | `.env` 改過密碼，但資料庫是用**舊密碼**建的。PG 密碼只在首次建庫時寫入——要 `docker compose down -v`（★刪資料）再 `up` |
| `database "fms" does not exist` | `.env` 的 `POSTGRES_DB` 跟你填的不一致 |
| 連得上但看不到表 | 表還沒建（你還沒寫 migration），或看錯 schema——DBeaver 左側展開 `fms ▸ Schemas ▸ public ▸ Tables` |
| Host 填 `db` 連不上 | `db` 只在 Docker 內部網路有效，從宿主機一律用 `localhost` |

### 兩個實用技巧

**① 測試庫另開一條連線。** `fms`（正式）與 `fms_test`（測試）各建一條，
名字改清楚。[SDD §6](../docs/SDD.md) 規定測試禁連正式庫——連線名字取好，手滑的機率會低很多。

**② 看得到 `EXCLUDE` 約束。** 展開 `Tables ▸ tasks ▸ Constraints`，
你加的 `no_overlap_work_station` 會列在那。做 M4 排程衝突時，
在 DBeaver 開兩個 SQL 編輯器分頁（＝兩條連線）同時 INSERT 重疊時段，
可以**親眼看到一條成功、一條被擋回 `23P01`**——比讀文件有感。

> pgvector 是本映像內建的，但要用才 `CREATE EXTENSION vector;`（本次作業用不到，
> 見 [SDD §10](../docs/SDD.md)）。

## 常用指令

| 目的 | 指令 |
|---|---|
| 起服務 | `docker compose up -d` |
| 只起資料庫（不要 MinIO） | `docker compose up -d db` |
| 看狀態 | `docker compose ps` |
| 看日誌 | `docker compose logs -f db` |
| 進 psql | `docker compose exec db psql -U fms -d fms` |
| 停止（**資料保留**） | `docker compose down` |
| 清空（**★資料一起刪**） | `docker compose down -v` |

## ⚠ 這份跟你要交的 compose 是兩回事

ACC-7 驗收要的是**三服務**（`db` + `backend` + `frontend`），規格見
[`../docs/SDD.md`](../docs/SDD.md) **§9**——那一份要**你自己寫**，放在專案根目錄。

```
fms-v3/
├── docker-compose.yml     ← ★你要寫的:交付形態(db + backend + frontend)
├── infra/
│   └── docker-compose.yml ← 本檔:開發期環境(db + minio)
├── backend/
└── frontend/
```

兩份分開放的理由：開發期你天天在改 backend，不該每次都連帶重建資料庫；
而交付驗收時要的是「一鍵全起」。混在一份裡兩邊都不好用。

## 疑難排解

**`backend/` 還沒建，可以直接 `up` 嗎？** —— 可以。compose 掛載了
`../backend/src/db/init`，該目錄不存在時 Docker 會**自動建成空目錄**，不會報錯
（2026-08-25 實測）。空的 init 目錄不影響資料庫啟動。

**backend 連不上資料庫** —— 先確認 `docker compose ps` 是 `healthy`（不是 `starting`）。
PG 容器「起來了」不等於「可接受連線」，這是 [GUIDE §2 坑 9](../docs/GUIDE.md)。

**port 5432 被占用** —— 本機已經裝過 PostgreSQL。改 `.env` 的 `POSTGRES_PORT`（例如 `5433`），
記得 `PGPORT` 也要一起改。

**密碼改了但沒生效** —— PG 的密碼只在**資料庫第一次建立時**寫入。改密碼要
`docker compose down -v`（★會刪資料）再 `up`。

---

## 實測紀錄

### 2026-09-02 複驗（infra/ 刪除後加回，逐項重跑）

環境：Docker 29.5.3 / Compose v5.1.4，WSL2 Ubuntu。測試用 `.env` 將埠改至
5435 / 9006 / 9007，避開機器上既有的 `pg-oracle-bridge`、`octo_*`、`aicpa_*` 服務。

| # | 驗證項 | 結果 |
|---|---|---|
| 1 | 無 `.env` 啟動 | 擋下，印出自訂訊息 |
| 2 | `docker compose config` | OK |
| 3 | `up -d` | db、minio 皆 `healthy` |
| 4 | PostgreSQL 版本 | **17.11** |
| 5 | 擴充 | `vector 0.8.6`、`btree_gist 1.7` |
| 6 | `createdb fms_test` | OK |
| 7 | `EXCLUDE` 重疊阻擋 | 擋下 |
| 8 | 邊界接續 10:00 接 10:00 | 通過（`'[)'` 正確） |
| 9 | 與 `Finished` 重疊 | 通過（部分索引生效） |
| 10 | **並行 race**（兩連線同搶） | **恰好一條成功**，另一條 `23P01`，表中最終 1 筆 |
| 11 | `down` → `up` 資料 | **保留**（5 筆） |
| 12 | `db/init/*.sql` 首次建庫執行 | **成功** |
| — | MinIO S3 API / Console | HTTP 200 / 200 |
| — | 跨檔引用（SDD §5/§6/§9/§10、GUIDE 坑 9） | 章節皆存在 |

> 測試後 `down -v` 全清（容器、volume、`.env`、`backend/` 測試目錄），
> 機器上既有的 12 個服務未受影響。

### 2026-08-25 首次實測

環境：Docker 29.5.3 / Docker Compose v5.1.4，WSL2 Ubuntu on Windows 11。
測試時以 `.env` 把 port 改到 5xxxx 區段避開既有服務——**這本身也驗證了
`POSTGRES_PORT` / `MINIO_*_PORT` 覆蓋機制可用**。

| # | 驗證項 | 結果 |
|---|---|---|
| 1 | 沒有 `.env` 就啟動 | **正確擋下**，印出「請先 cp .env.example .env 並設定密碼」 |
| 2 | `docker compose up -d` | db、minio 皆 `healthy` |
| 3 | MinIO healthcheck `mc ready local` | 可用（`healthy`）；S3 API 與主控台皆 HTTP 200 |
| 4 | PostgreSQL 版本 | **17.11** |
| 5 | 擴充可用性 | `vector 0.8.6`、`btree_gist 1.7` |
| 6 | `createdb -U fms fms_test` | 成功 |
| 7 | `down` → `up` 後資料 | **保留**（具名 volume；ACC-7） |
| 8 | `db/init/*.sql` 首次建庫自動執行 | **成功** |
| 9 | `backend/` 不存在時掛載 | **不會報錯**，Docker 自動建空目錄 |

**[SDD §5](../docs/SDD.md) 的 `EXCLUDE USING gist` 約束**（本課教學核心）逐項實測：

| 情境 | 預期 | 實測 |
|---|---|---|
| 同工作站時段重疊（09:30–10:30 撞 09:00–10:00） | 擋下 | **擋下**，SQLSTATE `23P01` |
| 邊界接續（10:00–11:00 接 09:00–10:00） | 通過 | **通過**（證實 `'[)'` 含頭不含尾） |
| 不同工作站同時段 | 通過 | **通過** |
| 與已 `Finished` 的任務重疊 | 通過 | **通過**（部分索引 `WHERE status <> 'Finished'` 生效） |
| **兩條連線同時搶同一時段** | 恰好一條成功 | **恰好一條成功**，另一條收 `23P01`；資料表最終只有 1 筆 |

> 最後一列是換成真 PG 伺服器最重要的收穫：**race condition 真的重現得出來，
> 也真的擋得住**。嵌入式單連線資料庫做不到這個測試。
