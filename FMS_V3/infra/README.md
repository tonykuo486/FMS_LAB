# infra — 開發期基礎設施

**這個目錄不是你的交付物，是給你用的環境。**
裡面只有「開發時需要、但你不必自己寫」的外部服務：資料庫與物件儲存。

| 服務 | 內容 | 本次作業 |
|---|---|---|
| `db` | PostgreSQL 17 + pgvector | **必要**（SRS TECH-4 / 2.1.5） |
| `minio` | S3 相容物件儲存 | **用不到**，為將來 ETL／檔案上傳預留 |

## 起手（第一天就做這個）

```bash
cd infra
cp .env.example .env      # ★把裡面的密碼全部改掉
docker compose up -d
docker compose ps         # 兩個都 healthy 才算起好
```

建測試資料庫（SRS 2.1.6：測試禁連正式庫），**只做一次**：

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
[`../docs/SRS.md`](../docs/SRS.md) **2.1.9**——那一份要**你自己寫**，放在專案根目錄。

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

**`docker compose up` 說路徑不存在** —— compose 掛載了 `../backend/src/db/init`，
你還沒建 `backend/` 時會失敗。把 compose 裡那一行先註解掉，等建好再打開。

**backend 連不上資料庫** —— 先確認 `docker compose ps` 是 `healthy`（不是 `starting`）。
PG 容器「起來了」不等於「可接受連線」，這是 SRS 附錄 B 坑 9。

**port 5432 被占用** —— 本機已經裝過 PostgreSQL。改 `.env` 的 `POSTGRES_PORT`（例如 `5433`），
記得 `PGPORT` 也要一起改。

**密碼改了但沒生效** —— PG 的密碼只在**資料庫第一次建立時**寫入。改密碼要
`docker compose down -v`（★會刪資料）再 `up`。
