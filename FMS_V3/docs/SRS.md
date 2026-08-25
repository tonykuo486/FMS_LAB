# 需求規格書（Lastenheft）：工廠管理系統（Factory Management System）

**程式設計專題 WI（Programming Project WI）** ｜ v3.6（2026-08-25）：TypeScript 全棧版（PostgreSQL 17；版本鎖定見 2.1.11）

---

## 1. 概述（Overview）

工廠需要軟體來在多個據點之間排程生產任務。其挑戰特別包含：排程（scheduling）與工作站分配（work station allocation）。本專案要實作一套工廠管理系統，讓據點主管（site managers）能更輕鬆地規劃任務，並提供操作員（operators）一個簡易的方式來檢視並登記不同生產據點的每週班次。

生產規劃的工作流程依照以下步驟進行。在一個每週生產週期開始時，「產品（Products）」及其各自的「製程（Processes）」會被確認定案。操作員會針對特定的「生產據點（Production Sites）」與「週次（Weeks）」進行登記。據點主管依據這些登記，透過將產品與特定製程組合來決定任務（task）的指派。每一項任務都會分配一個工作站（work station）與一個時段（time slot），以確保：避免排程衝突、操作員持有該製程所需的證照（certification）、且工作站具備該製程所需的技術能力（technical capability）。任務完成後，操作員將該任務標記為「Finished（已完成）」，讓據點主管能夠監控進度與完成狀態。

詳細需求列於第 2 章。第 3 章描述不屬於本專案範圍，因此不需要被實作的元素。

---

## 2. 需求（Requirements）

### 2.1 技術規格（Technical Specifications）

本專案採用 **TypeScript 全棧**：前後端同一種語言、同一套型別，從資料庫到畫面端到端型別安全。

| 編號              | 內容                                                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **TECH-1**  | 實作語言為 **TypeScript 5.9.3**（`strict: true`），執行環境 **Bun 1.4.0**（runtime + 套件管理 + 測試器三合一）；**版本一律照 2.1.11 鎖定表寫死** |
| **TECH-2**  | 後端框架：**Elysia**（REST API，路由層以內建 `t`（TypeBox）宣告請求 schema）；前端框架：**Refine + Ant Design**（React 18 + Vite）      |
| **TECH-3**  | 持久性資料儲存於一個 SQL 資料庫（**PostgreSQL 17**），資料表結構以冪等 SQL（`CREATE TABLE IF NOT EXISTS`）於啟動時建立；schema 變更以**版本化 migration 檔**累加（`db/migrations/NNN_*.sql`），不改舊檔 |
| **TECH-4**  | 資料庫使用**獨立的 PostgreSQL 伺服器**，以 Docker Compose 提供（映像 `pgvector/pgvector:0.8.6-pg17`＝PG 17 內建 pgvector）；後端經 TCP 以**連線池**（`pg`／node-postgres）存取；資料落在具名 volume，**不放容器層**。開發期不需在本機安裝 PG——repo 附 `infra/`，`cd infra && docker compose up -d` 即得（部署規格見 2.1.9） |
| **TECH-5**  | **開發期**用開發伺服器：先 `cd infra && docker compose up -d` 起資料庫，再 `bun run --watch src/index.ts`（後端）與 `vite`（前端，`/api` 反向代理到後端）；**交付與驗收必須以 Docker Compose 全棧啟動**（見 TECH-13）  |
| **TECH-6**  | 使用者介面以 React + Ant Design 元件實作（由元件庫產出語法正確的 HTML，不手寫裸 HTML/CSS）                                              |
| **TECH-7**  | 程式碼必須能在 Windows、macOS 與 Linux 上執行（Bun、Vite 跨平台無原生編譯依賴；PostgreSQL 統一走 Docker，三平台行為一致）                  |
| **TECH-8**  | 程式碼必須以單元測試（**`bun test`**）加以保護；排程衝突檢核等核心業務邏輯須有獨立測試                                                   |
| **TECH-9**  | 所有使用者輸入必須驗證：路由層 Elysia `t` schema + 服務層 **Zod**；SQL 一律**參數化**（`$1, $2…`，禁字串拼接）；認證採 **JWT（`jose`）存 httpOnly cookie（`SameSite=Lax` 防 CSRF）**；每個端點掛角色守衛防未授權存取 |
| **TECH-10** | 語意上不正確的使用者輸入必須以清楚的錯誤訊息加以拒絕（HTTP 400 + 人話訊息，不可回傳 stack trace）                                        |
| **TECH-11** | 系統必須具備可調整性（adaptable）；產品（products）、製程（processes）、證照（certifications）與據點（sites）不可硬編碼（hard-coded） |
| **TECH-12** | **完全離線可用，禁用任何 CDN**：所有依賴皆為 npm 套件由 Vite 打包（AntD 樣式與 icons 從套件 import，天生無 CDN）；字型用系統字型堆疊，**不得引用 Google Fonts / 外部字型**；教室部署以預抓好的 Bun 離線快取＋lockfile 還原（`bun install --offline`）；**PostgreSQL 映像須預先 `docker save` 帶進教室**（離線四件套見 2.1.9） |
| **TECH-13** | **必須能以 Docker Compose 部署於單機**（Docker Desktop）：repo 附前後端 `Dockerfile` + `docker-compose.yml`，`docker compose up -d` 一鍵啟動即可使用；**build 過程零外網**（依賴走 TECH-12 的離線快取），基底映像以 `docker save`/`docker load` 預載（部署規格見 2.1.9） |

#### 2.1.1 系統架構

```
瀏覽器（Refine + Ant Design；vite dev 5173）
   │  /api/*（vite proxy 轉發到後端）
   ▼
Bun + Elysia 後端（3000）
   ├─ routes/     路由層：t schema 驗參 + JWT 解析 + 角色守衛
   ├─ services/   業務層：排程衝突檢核、證照/能力匹配、狀態機（In Planning→Scheduled→Finished）
   └─ db/         資料層：templates/（具名 SQL 模板：name + sql + params schema）
                        + pool.ts（pg 連線池單例）+ migrations/
   ▼  TCP 5432（連線池）
PostgreSQL 17 + pgvector（Docker 服務 `db`；資料在具名 volume `fms_pgdata`）
   └─ 測試用同一台 PG,每個測試檔開自己的 schema（見 2.1.6）
```

分層鐵律：**路由不寫業務邏輯、業務層不碰 HTTP、SQL 只存在於 `db/templates/`**。
前端永遠只呼叫 REST API（resource + 參數），永遠不傳 SQL。

#### 2.1.2 技術選型明細（完整 TS 生態）

| 關注點 | 套件 | 用途 |
|---|---|---|
| Runtime / 套件管理 / 測試 | **Bun 1.4.0** | `bun install` / `bun run` / `bun test` 一把抓，免 Node+npm+jest 三件套 |
| 後端 HTTP | **elysia** + **@elysiajs/cors** | 路由、TypeBox 驗參、CORS |
| 前端框架 | **@refinedev/core** + **@refinedev/antd** | 資源導向 CRUD 框架（詳 2.1.4） |
| UI 元件 | **antd 5.29.3**、**@ant-design/icons 5.6.1** | 表格/表單/週曆檢視全用現成元件（**不可升 antd 6**,見 2.1.11） |
| 建置 | **vite** + **@vitejs/plugin-react** | 前端 dev server 與打包 |
| 資料庫 | **PostgreSQL 17**（映像 `pgvector/pgvector:0.8.6-pg17`） | 真 PG 伺服器,內建 pgvector（詳 2.1.5） |
| DB 驅動 / 連線池 | **pg**（`node-postgres`） | **顯式**連線池（`new Pool` / `client.release()`）、參數化查詢——選它的理由見 2.1.11 |
| 驗證 | **zod 3.x**（服務層）/ Elysia `t`（路由層） | 雙層驗證：邊界擋格式、服務擋語意 |
| 認證 | **jose** | JWT 簽發/驗證（HS256），httpOnly cookie |
| 密碼 | **Bun.password**（內建 argon2id） | 免額外套件 |
| CSV 匯入 | **papaparse** | PERS-15 三類 CSV 上傳解析 |
| 程式品質 | **typescript 5.9.3**（`tsc --noEmit`）、**biome**（lint + format 單一工具） | CI 三綠燈之二（**不使用 TS 7**,理由見 2.1.11） |
| CI | **GitHub Actions** | push 即跑 `install → typecheck → test`（見 2.1.6） |

> **完整鎖定版本見 2.1.11 版本鎖定表（2026-08-25 實測核實）**——`package.json` 一律寫死
> 版本號不加 `^`;`bun.lock` 進版控,學員 `bun install` 即還原一致環境。

#### 2.1.3 專案結構（monorepo，單一 GitHub repo）

```
fms/
├── backend/
│   ├── src/
│   │   ├── index.ts          # Elysia 入口（掛 cors、cookie、路由群）
│   │   ├── routes/           # sites.ts / tasks.ts / registrations.ts / auth.ts / admin.ts / csv.ts
│   │   ├── services/         # scheduling.ts（衝突/證照/能力檢核）、tasks.ts、auth.ts
│   │   └── db/
│   │       ├── pool.ts       # pg 連線池單例（含測試用 schema 工廠）
│   │       ├── init/         # 首次建庫自動執行(compose 掛載到 docker-entrypoint-initdb.d)
│   │       ├── schema.sql    # 冪等建表（測試建 schema 時直接灌這支）
│   │       ├── migrations/   # 版本化 migration：001_init.sql, 002_*.sql…（只增不改）
│   │       └── templates/    # 具名 SQL 模板（每條：name + sql + zod params）
│   ├── tests/                # bun test（每檔開自己的 PG schema,見 2.1.6）
│   ├── package.json
│   └── tsconfig.json
├── frontend/
│   ├── src/
│   │   ├── App.tsx           # Refine：resources、authProvider、accessControlProvider
│   │   ├── providers/        # dataProvider（打 /api）、authProvider、accessControlProvider
│   │   └── pages/            # tasks/ sites/ registrations/ admin/ public-board/
│   ├── package.json
│   └── vite.config.ts        # /api proxy → http://localhost:3000
├── testdata/                 # ACC-1 主測試集 + ACC-4 千筆任務集（CSV）
├── infra/                    # ★repo 已附:開發期環境(不是交付物)
│   ├── docker-compose.yml    #   db(PG 17 + pgvector) + minio
│   ├── .env.example          #   連線參數範本（真 .env 不進版控）
│   └── README.md             #   起手指令與疑難排解
├── docker-compose.yml        # ★由你撰寫:交付形態三服務(db + backend + frontend),ACC-7 驗這份
├── .github/workflows/ci.yml  # CI 起 postgres service container
└── README.md                 # 上手指令：起 db → bun install ×2 → 兩個 dev → 匯入測試集
```

#### 2.1.4 權限模型（RBAC）——Refine 對應 Django Admin 的作法

本專案有四種角色（詳 2.4）。Refine **沒有**「開箱即用的 Django admin」，但以三個 provider
組合可達到等價功能，且權限邏輯是顯式程式碼（教學上更透明）：

| Django 概念 | Refine 對應 | 本專案落法 |
|---|---|---|
| `ModelAdmin` 自動 CRUD 介面 | `resources` 宣告 + `List/Create/Edit/Show` 頁（可先用 **Inferencer** 自動生成再客製） | admin 區：users / sites / certifications / capabilities 四資源 |
| `User.is_staff` / 登入 | **`authProvider`**（login/logout/check/getIdentity） | 打 `/api/auth/*`，JWT 存 httpOnly cookie，`getIdentity` 回角色 |
| Model permissions（add/change/delete/view） | **`accessControlProvider.can({ resource, action })`** | 依 JWT 角色查權限矩陣（下表）；`can=false` 時 Refine **自動隱藏選單、禁用按鈕、擋路由** |
| admin site 只給 staff | resource 級 `can` + 後端路由守衛 | **前端擋 UX、後端擋安全**——後端守衛才是真防線（TECH-9），前端只是體驗 |

**權限矩陣（前後端共用同一份定義，放 `shared` 型別）**：

| resource × action | Admin | Site Manager | Operator | Anonymous |
|---|---|---|---|---|
| users / certifications / capabilities（CRUD） | ✅ | ✗ | ✗ | ✗ |
| sites（CRUD） | ✅ | 讀（僅所屬據點） | 讀 | 讀 |
| tasks：建立/指派/定案 | ✅ | ✅（僅所屬據點） | ✗ | ✗ |
| tasks：標記 Finished | — | — | ✅（僅被指派者） | ✗ |
| tasks：檢視 | ✅ | ✅（所屬據點） | ✅（已排程＋自身資格） | ✅（**操作員姓名匿名化**） |
| registrations（登記據點×週次） | ✅ | 讀 | ✅（自己的） | ✗ |
| CSV 匯入 | ✅ | ✅（所屬據點） | ✗ | ✗ |

> 進階選配：權限矩陣可改以 **Casbin**（`casbin` npm 套件）定義 model/policy，Refine 官方有
> accessControlProvider × Casbin 整合範例——教學上列為加分題，預設用上表的純 TS 矩陣即可。

##### 為什麼本課**不**採用「資料表驅動」的 RBAC

業界常見的 RBAC 做法是把權限存進資料庫（典型五張表：`user` / `role` / `permission` /
`role_permission` / `user_role`，再加一支 `check_user_permission(user, code)` 函式，
配 Redis 快取權限查詢結果）。這是**正確且成熟**的設計，規模大時該這樣做。

**但本課刻意不用**，理由是教學順序：

| | 資料表驅動 RBAC | 本課的 TS 權限矩陣 |
|---|---|---|
| 權限定義在哪 | 資料庫的列（要查表才知道） | **原始碼裡的一張表**（2.1.4 上表，看得見） |
| 改權限 | 改資料 + 清快取 | 改程式碼 + 型別檢查會抓錯 |
| 新增角色 | 多筆 insert | 矩陣多一欄，**漏掉哪個 resource 編譯器會報** |
| 要多學 | 五張表 + 快取失效 + 遞迴查詢 | 無 |
| 適合 | 權限要**執行期由管理員調整** | 權限**在設計時就定死**（本課正是如此） |

FMS 的四個角色（Admin／Site Manager／Operator／Anonymous）是**需求寫死的**
（PERS-3~25），不需要執行期新增角色。這種情況下，把權限放進資料庫只會多一層間接、
多一個快取失效的 bug 來源，卻學不到更多東西。

**真正該學會的是這條鐵律，兩種做法都一樣**：
> **前端擋 UX、後端擋安全。** `accessControlProvider` 讓按鈕消失＝體驗；
> 後端每個端點自己的角色守衛＝安全。少了後端那層，權限模型再漂亮都是裝飾。

> 有興趣做資料表驅動 RBAC 的，列為**加分題**（與 Casbin 同級）——但**先把上表的矩陣
> 與後端守衛做完**再說。順序反了會兩頭空。

#### 2.1.5 資料庫（PostgreSQL 17）使用規範

- **是什麼**：**獨立的 PostgreSQL 17 伺服器**，由 Compose 的 `db` 服務提供，
  後端經 TCP 以連線池存取。映像用 `pgvector/pgvector:0.8.6-pg17`——就是官方 PG 17
  加裝 pgvector 擴充，現在不用向量也完全不影響，但將來要做向量檢索時**不必換映像、
  不必重建資料**（見 2.1.10 未來擴充路線）。
- **為什麼用真 PG 而不是嵌入式資料庫**：這是**實戰經驗**的取捨。真 PG 伺服器帶來
  嵌入式庫學不到的四件事：
  1. **連線池**——連線是有限資源，池會滿、會逾時；`max` 怎麼設、連線何時歸還，
     是每個後端工程師都要會的。
  2. **真正的並行**——多請求同時打同一張表才會**真的**產生 race condition；
     嵌入式單連線是序列化的，race 根本重現不出來（下面第 4 點是本課的心臟）。
  3. **連線設定與機敏資訊管理**——host/port/密碼進環境變數、`.env` 不進版控，
     這是離開教室後每天都要面對的事。
  4. **可被外部工具連線**——psql、DBeaver、ETL 工具、BI 都能連進來看同一份資料；
     嵌入式資料庫做不到，而這正是資料能流向資料倉儲的前提（2.1.10）。
- **連線規範**：
  - 後端以 **`pg` 連線池單例**（`db/pool.ts`，`new Pool({ max: 10 })`）存取，**禁止**每個請求
    開新連線;取得的 client **務必 `release()` 歸還**（用 `try/finally` 包）。
  - 連線參數一律走環境變數（`PGHOST`/`PGPORT`/`PGDATABASE`/`PGUSER`/`PGPASSWORD`），
    repo 只放 `.env.example`；**真 `.env` 不進版控**（TECH-9）。
  - SQL 一律參數化（`$1, $2…`），禁字串拼接（2.1.7 鐵律 2）。
- **schema 演進**：`db/migrations/NNN_*.sql` 版本化累加，**只增不改舊檔**——
  改了舊檔，已經跑過的機器不會重跑，你的資料庫和同學的就長得不一樣了。
- **排程衝突的資料庫層防線（本課心臟）**：TASK-6（同據點同時段工作站/人員不可重疊）
  除服務層檢核外，加 **`EXCLUDE USING gist` 約束**當最後防線：

  ```sql
  -- btree_gist 必裝:gist 索引預設不支援純量欄位的 = 運算子
  CREATE EXTENSION IF NOT EXISTS btree_gist;

  ALTER TABLE tasks ADD CONSTRAINT no_overlap_work_station
    EXCLUDE USING gist (
      work_station_id WITH =,
      -- '[)' = 含頭不含尾:09:00-10:00 與 10:00-11:00 **不算**重疊(邊界接續是合法的)
      tstzrange(starts_at, ends_at, '[)') WITH &&
    ) WHERE (status <> 'Finished');
  ```

  操作員的重疊約束同理（`operator_id WITH =`）。
  > **兩個細節值得想清楚**：
  > ① `'[)'` 邊界——不寫的話預設也是 `[)`,但**明寫出來**代表你知道自己在決定
  >   「10:00 結束的任務和 10:00 開始的任務算不算撞」（答案:不算,這才合理）。
  > ② `WHERE (status <> 'Finished')` 是**部分索引**——已完成的歷史任務不該再
  >   擋住新排程。想一下這個判斷對不對,它會直接影響 ACC-4 千筆資料下的行為。
  > **換成真 PG 之後，這一條才真的可驗**：開兩個連線同時 INSERT 重疊時段，
  > 服務層檢查會**雙雙通過**，但資料庫會擋下其中一個（`23P01` exclusion_violation）。
  > 請寫一個並行測試證明它——這是「應用層檢查會有 race，資料庫約束才是底」
  > 從口號變成你**親手驗過**的事實。
  >
  > ✅ **上面這段已於 2026-08-25 在 PG 17.11 實測**：兩條連線同時搶同一工作站
  > 同一時段，**恰好一條成功**、另一條收到 `23P01`，資料表最終只有一筆;
  > 邊界接續（10:00 接 10:00）通過、與 `Finished` 任務重疊通過（部分索引生效）。
  > 完整紀錄見 [`../infra/README.md`](../infra/README.md)「實測紀錄」。

#### 2.1.6 測試策略與 CI

| 層 | 工具 | 內容 |
|---|---|---|
| 單元測試 | `bun test` | services 層：衝突檢核（時段重疊/跨日/超 6 小時/非 5 分鐘倍數）、證照/能力匹配、狀態機轉移、匿名化 |
| **並行測試** | `bun test` | **TASK-6 race**：兩條連線同時搶同一工作站同一時段 ⇒ 恰好一條成功、另一條收到 `23P01`（2.1.5 心臟條款） |
| API 測試 | `bun test` + Elysia `handle()` | 路由層：驗參 400、未登入 401、越權 403、正常流 200 |
| 驗收展示 | `testdata/` 兩套 CSV | ACC-1 主測試集手動走流程；ACC-4 千筆集匯入後實測新增任務無可察覺變慢 |
| CI | GitHub Actions | 起 `postgres` service container → `bun install` → `tsc --noEmit`（前後端）→ `bun test`；main 分支保護：PR + CI 綠才可 merge |

**測試隔離：一個測試檔 = 一個 schema。** 換成真 PG 後不再有 in-memory 實例可用，
改用 PG 自己的 schema 當隔離單位——同一台 PG、各測試檔互不干擾，且**平行安全**：

```ts
// tests/helpers/db.ts
const id = `test_${crypto.randomUUID().replaceAll('-', '')}`;
await sql`CREATE SCHEMA ${sql(id)}`;
await sql`SET search_path TO ${sql(id)}`;
await sql.file('src/db/schema.sql');       // 在這個 schema 裡建表
// …測試結束
await sql`DROP SCHEMA ${sql(id)} CASCADE`;
```

**規範**：
1. 測試**禁止**連正式資料庫——CI 與本機都用獨立的 `fms_test` 資料庫（`.env.test`）。
2. schema 名用隨機字串，**不要**用測試檔名（同檔平行跑多個 case 會撞）。
3. `afterAll` 一定 `DROP SCHEMA … CASCADE`——忘了清，PG 裡會堆滿殘骸。
4. 測 race 的案例**必須開兩條真連線**（不能共用同一條）,否則測不到並行。

#### 2.1.7 SQL 資產化規範（query-template，TS + Zod）

`db/templates/` 的每一條 SQL 都是**一等公民資產**，必須以下列介面宣告（不是散落在程式裡的字串）：

```ts
import { z } from 'zod';

export interface QueryTemplate {
  name: string;                        // 口徑名（人話，例：「週次任務清單」）
  source: string;                      // 溯源：對應本 SRS 的需求編號（例：'TASK-6, FACT-7'）
  sql: string;                         // 參數化 SQL（$1,$2… 或具名參數;禁字串拼接）
  params: z.ZodObject<z.ZodRawShape>;  // 參數 schema（執行前先 parse，不合法直接 400）
}

// 範例：某週某據點的已排程任務（匿名視角）
export const publicWeekTasks: QueryTemplate = {
  name: '公開看板-週任務',
  source: 'PERS-24, PERS-25',          // 匿名化+據點/週次篩選的需求出處
  params: z.object({
    site_id: z.number().int().positive(),
    year:    z.number().int().min(2020).max(2100),
    week:    z.number().int().min(1).max(53),   // ISO 8601（FACT-2）
  }),
  sql: `SELECT t.id, p.name AS product, pr.name AS process,
               ws.name AS work_station, t.starts_at, t.ends_at,
               'Operator ' || dense_rank() OVER (ORDER BY t.operator_id) AS operator_alias
        FROM tasks t
        JOIN products p   ON p.id = t.product_id
        JOIN processes pr ON pr.id = t.process_id
        JOIN work_stations ws ON ws.id = t.work_station_id
        WHERE t.site_id = $1 AND t.year = $2 AND t.week = $3
          AND t.status = 'Scheduled'`,
};
```

**四條鐵律**：
1. **`source` 必填**——每條 SQL 都要能回答「這條口徑是為了哪一條需求存在」；驗收時
   逐條需求可反查到實作（需求 ↔ SQL 雙向可追溯，這是本課程的工程紀律重點）。
2. **禁字串拼接**——參數一律 `$n` 佔位；`params` schema parse 失敗即 400（TECH-9/10）。
3. **前端永不傳 SQL**——REST API 只收 resource + 參數；模板名單即白名單。
4. **一模板一口徑**——同一數字兩處要用，抽同一條模板，不複製 SQL（口徑分叉是排程系統
   最貴的 bug）。

#### 2.1.8 UI 設計規範（Steel Blue 主題）

整體視覺走**「深海軍藍側欄 + 鋼藍主色 + 冷灰藍亮內容區」**的企業風格（沉穩、專業、
長時間看表不累）。所有色票如下，實作時集中定義於 `frontend/src/theme.ts`，**禁止散寫**。

**（a）主色與內容區**

| token | 值 | 用途 |
|---|---|---|
| `colorPrimary` | **`#2E6DA4`**（鋼藍） | AntD 主色：按鈕/連結/選中態/focus |
| `appBg` | `#f4f6f9` | 頁面底（極淺冷灰藍，非純白非暖米） |
| `containerBg` | `#ffffff` | 卡片純白 |
| `textBase` / `textSecondary` | `#2a3442` / `#697485` | 深藍灰正文/次要字 |
| `border` / `tableHeader` | `#e2e8f0` / `#eef2f7` | 冷灰藍邊框/表頭 |

**（b）左側 Sidebar（恆深，不隨主題變亮）**

| token | 值 | 用途 |
|---|---|---|
| `sider.bg` / `sider.subBg` | **`#152a42`** / `#0f2033` | 深海軍藍底/子選單再深一階做層次 |
| `sider.text` / `textHover` | `#b3c4d9` / `#ffffff` | 未選中柔白偏藍/hover 純白（hover 底 `rgba(255,255,255,.07)`） |
| `sider.selectedBg` | **`#2e6da4`**（白字） | 選中=鋼藍實心塊 |
| `sider.border` / `groupTitle` | `#22405f` / `#6d84a0` | 內分隔線/群組標題 |

**Sidebar 行為（RWD 兩態）**：
- 桌面（≥992px）：Sider **常駐**，漢堡鈕在 **200px ↔ 80px（純圖示條）** 之間折疊；
- 窄屏（<992px）：Sider 改 **Drawer 抽屜**，漢堡鈕左滑出，點選單項後自動關閉；
- 選單分群依角色渲染（`accessControlProvider` 判定，見 2.1.4）：任務排程／我的班表／
  公開看板／系統管理（僅 Admin 可見）;
- **Sider 底部＝使用者身分區**：登入者姓名＋角色＋所屬據點選擇器（Site Manager 多據點
  時可切，單據點鎖死）＋登出。

**（c）登入頁**（全深色，聚焦表單）

| 元素 | 規格 |
|---|---|
| 頁面底 | `#152a42` 滿版，`display:grid; place-items:center` 置中 |
| 卡片 | `max-width:380px`，底 `#1c3552`，`border-radius:12px`，陰影 `0 8px 32px rgba(0,0,0,.3)` |
| 標題 | 系統名，鋼藍 `#2e6da4`、22px、700;副標 `#94a3b8` 12px |
| 表單 | Email＋密碼（PERS-2）;label 淺灰藍 `#cbd5e1`;錯誤訊息具體（TECH-10）但**不揭露帳號是否存在** |
| 匿名入口 | 卡片下方連結「以訪客瀏覽公開看板 →」（PERS-23~25） |

**（d）頁內分類切換＝膠囊 Tabs（全站統一，不用 AntD 預設下劃線 Tabs）**

```css
/* pill-tabs.css：未選中=白底細邊膠囊;hover=鋼藍描邊;選中=鋼藍實心+白字 */
.pill-tabs > .ant-tabs-nav::before { border-bottom: none; }
.pill-tabs > .ant-tabs-nav .ant-tabs-ink-bar { display: none; }
.pill-tabs .ant-tabs-tab {
  background:#fff; border:1px solid #dfe8f1; border-radius:16px;
  padding:3px 14px; font-size:12px; color:#445;
}
.pill-tabs .ant-tabs-tab:hover { border-color:#2E6DA4; color:#2E6DA4; }
.pill-tabs .ant-tabs-tab-active { background:#2E6DA4; border-color:#2E6DA4; }
.pill-tabs .ant-tabs-tab-active .ant-tabs-tab-btn { color:#fff; font-weight:700; }
```

**設計驗收**：任何新頁面不得出現規範外色票；Tabs 一律套 `.pill-tabs`;
「同一件事全站長同一個樣子」列入 code review 檢核。

#### 2.1.9 Docker Compose 部署規格（TECH-13）

> **開發期環境已附在 repo：[`../infra/`](../infra/)** ——只含 `db`（PostgreSQL 17 +
> pgvector）與 `minio`，`cd infra && docker compose up -d` 就有資料庫可用，
> 不必手動裝 PG。**該份已於 2026-08-25 實測通過**（兩服務皆 `healthy`、
> `down`/`up` 資料保留、`db/init/` 自動執行）——見 `infra/README.md` 實測紀錄。
>
> **但 `infra/` 不是交付形態。** 本節規格的三服務 compose（含 backend / frontend）
> 要**你自己寫在專案根目錄**，ACC-7 驗收跑的是那一份。兩份刻意分開：開發期天天改
> backend 不該連帶重建資料庫；驗收時要的則是「一鍵全起」。

單機（Docker Desktop）、**三服務**：`db`（PostgreSQL）＋`backend`（Bun/Elysia）＋
`frontend`（nginx 服務靜態檔並反代 `/api`）。只有 frontend 對外露 port。

```yaml
# docker-compose.yml
services:
  db:
    image: pgvector/pgvector:0.8.6-pg17    # PG 17 + pgvector（版本鎖死,見 2.1.5）
    environment:
      POSTGRES_DB: fms
      POSTGRES_USER: fms
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?請在 .env 設密碼}   # ★不給預設值,逼你設
    volumes:
      - pgdata:/var/lib/postgresql/data     # ★具名 volume——容器重建資料不丟
    healthcheck:                            # ★backend 要等 db 真的可連,不是「容器起來」
      test: ["CMD-SHELL", "pg_isready -U fms -d fms"]
      interval: 5s
      timeout: 3s
      retries: 10
    # 不對外露 port:只有 backend 連得到。要用 psql/DBeaver 看資料時再自行加 ports

  backend:
    build: ./backend               # FROM oven/bun:1;bun install --offline（快取入 build context）
    environment:
      PGHOST: db
      PGPORT: "5432"
      PGDATABASE: fms
      PGUSER: fms
      PGPASSWORD: ${POSTGRES_PASSWORD:?}
    depends_on:
      db:
        condition: service_healthy          # ★等 healthcheck 過才啟動
    # 啟動時先跑 migrations 再開服務

  frontend:
    build: ./frontend              # 兩階段：oven/bun build(vite) → nginx:alpine 服務 dist
    ports: ["8080:80"]
    depends_on: [backend]

volumes:
  pgdata:
```

```nginx
# frontend/nginx.conf（反代要點）
location /api/ { proxy_pass http://backend:3000/; }   # 剝 /api 前綴 → 後端路由不帶前綴
location /     { try_files $uri /index.html; }        # SPA fallback
```

**規範**：
1. PG 資料一律在**具名 volume**（`pgdata`），**禁**放容器層；`down`/`up` 後資料須仍在
   （ACC-7 會實測）。注意 `docker compose down -v` 的 `-v` 會**刪掉 volume**——
   驗收前別手滑。
2. **密碼不進版控**：`POSTGRES_PASSWORD` 走 `.env`（repo 只放 `.env.example`）；
   compose 用 `${POSTGRES_PASSWORD:?}` 語法，**沒設就直接啟動失敗**，
   而不是靜靜用一個弱預設值跑起來。
3. **啟動順序**：`depends_on` 只保證「容器啟動」，不保證「PG 可連線」——
   必須配 `healthcheck` + `condition: service_healthy`，否則 backend 會在
   PG 還沒 ready 時連線失敗（附錄 B 坑 9）。
4. cookie 在 compose 拓撲下天然同源（瀏覽器只看到 :8080，`/api` 由 nginx 轉發）
   ——附錄 B 坑 7 的正解之二。
5. **離線四件套**：基底映像預載（`docker save oven/bun:1 nginx:alpine
   pgvector/pgvector:0.8.6-pg17 -o base.tar` → 教室機 `docker load`）＋ bun 離線快取
   入 build context ＋ lockfile ＋ `testdata/`——四者齊備即可斷網
   `docker compose up --build`。
   > ⚠ **PG 映像約 400MB，是四件套裡最大的一塊**——備課時務必先在教室機
   > `docker load` 驗過，別到上課才發現沒帶。
6. 驗收指令即文件：README 須含「`docker load` → 設 `.env` → `docker compose up -d`
   → 開 `http://localhost:8080`」四步，照打即通（ACC-7）。

#### 2.1.10 未來擴充路線（說明用，**不列入本次驗收**）

本節解釋「為什麼現在要換成真 PG」的長線理由。**這些都不是本次作業要做的**——
列在這裡是讓你知道今天的設計決策通往哪裡，不要為了未來過度設計今天的系統。

**今天的系統是 OLTP（線上交易處理）**：一次一筆任務的建立、指派、完成，
要求正確與即時。**資料分析是 OLAP（線上分析處理）**：跨月跨據點的稼動率、
瓶頸工作站、證照缺口——要掃大量歷史資料做聚合。

> **鐵律：不要在正式營運資料庫上跑大型分析查詢。** 一支掃三年歷史的聚合查詢
> 會拖垮正在排程的操作員。兩者要分開——這就是資料倉儲存在的理由，
> 也是 EXCL-2（報表功能不在範圍內）的技術背景。

**演進路徑**：

```
[今天] FMS 營運庫 (PG 17, OLTP)
          │
          │  ETL / CDC：定期或即時抽取
          ▼
[未來] 資料倉儲 (PG, OLAP)          ← 星型 schema:事實表(任務) + 維度表(據點/產品/製程/人員)
          ├─ pgvector：語意檢索與相似度
          └─ WrenAI：自然語言問資料("上個月哪個工作站最忙?")
```

| 元件 | 位置 | 做什麼 | 為何需要今天的真 PG |
|---|---|---|---|
| **ETL / CDC** | 營運庫 → 倉儲 | 定期抽取或以 logical replication 即時同步 | 嵌入式資料庫沒有 TCP 端點與 WAL,外部工具連不進來、也訂閱不到變更 |
| **pgvector** | 倉儲（本專案映像已內建） | 向量欄位與相似度檢索（如「找出類似的排程樣態」） | 已用 `pgvector/pgvector:0.8.6-pg17`,將來 `CREATE EXTENSION vector` 即可,**不必換映像、不必搬資料** |
| **WrenAI** | 倉儲之上 | 自然語言轉 SQL,對倉儲做聚合分析 | 需要一個它連得進去的標準 PG 端點,並依賴穩定的 schema 語意 |

**這條路線對你今天的作業有兩個實質影響**（都已寫進規格，做到即可）：

1. **SQL 模板的 `source:` 欄位**（2.1.7 鐵律 1）——每條 SQL 都能反查需求編號。
   將來建倉儲時，「這個數字的口徑是什麼」有據可查；口徑分叉是資料倉儲最貴的 bug。
2. **一模板一口徑**（2.1.7 鐵律 4）——同一個數字兩處要用就抽同一條模板。
   營運端口徑不一致，ETL 到倉儲只會把混亂放大。

> **GPU 運算（CUDA 等）不在資料庫層。** pgvector 在 PG 內做的是向量儲存與檢索；
> 若將來要做模型推論或大規模向量運算，那是**應用層**的事（獨立服務），
> 不會、也不該塞進 PG。這兩層別混為一談。

#### 2.1.11 版本鎖定表（**2026-08-25 實測核實**）

下表是**實際裝起來、跑起來、測過、打包過**的組合，不是查文件推論的。
`package.json` **一律寫死版本號（不加 `^` 或 `~`）**——教室三十台機器要長一模一樣。

**驗證方式**：以 Bun 1.4.0 全新安裝（無既有 lockfile）→ 執行 → `bun test` →
`tsc --noEmit` → `vite build`。結果：後端 **7/7 測試通過**、前端 **2/2 測試通過**、
前後端 typecheck 皆 **0 error**、Vite production build 成功（3,820 modules）。

**Runtime**

| 項目 | 版本 | 說明 |
|---|---|---|
| **Bun** | **1.4.0** | runtime + 套件管理 + 測試器三合一 |
| **PostgreSQL** | **17**（映像 `pgvector/pgvector:0.8.6-pg17`） | 見 2.1.5 |

**後端（`backend/package.json`）**

| 套件 | 版本 | 用途 |
|---|---|---|
| `elysia` | `1.4.29` | 路由 + TypeBox `t` 驗參 |
| `@elysiajs/cors` | `1.4.2` | CORS |
| `pg` | `8.23.0` | PostgreSQL 驅動與**連線池**（見下方選型說明） |
| `zod` | `3.25.76` | 服務層驗證（**3.x,不是 4.x**） |
| `jose` | `6.2.10` | JWT 簽發/驗證（HS256） |
| `papaparse` | `5.7.0` | CSV 匯入（PERS-15） |
| `typescript` | `5.9.3` | **不使用 TS 7**（見下方「為何不升」） |
| `@types/bun` | `1.4.0` | 對齊 runtime |
| `@types/pg` | `8.23.1` | — |
| `@types/papaparse` | `5.3.16` | — |

> 密碼雜湊用 **`Bun.password`**（內建 argon2id），不需額外套件（PERS-2）。

**前端（`frontend/package.json`）**

| 套件 | 版本 | 用途 |
|---|---|---|
| `react` / `react-dom` | `18.3.1` | **React 18,不是 19**（Refine 4 不支援 19） |
| `antd` | **`5.29.3`** | **★不可升 6.x**（見附錄 B 坑 11） |
| `@ant-design/icons` | `5.6.1` | 與 antd 5 同代 |
| `@refinedev/core` | `4.58.0` | 資源導向 CRUD 框架 |
| `@refinedev/antd` | `5.47.0` | Refine × antd 綁定 |
| `@tanstack/react-query` | `4.44.0` | **Refine 的 peer,必須自己裝**（漏了執行期才爆） |
| `dayjs` | `1.11.23` | Refine antd 的 peer |
| `vite` | `6.4.3` | dev server + 打包 |
| `@vitejs/plugin-react` | `4.3.4` | 與 Vite 6 同代 |
| `typescript` | `5.9.3` | 與後端同版 |
| `@types/react` / `@types/react-dom` | `18.3.18` / `18.3.5` | 對齊 React 18 |

##### 為何是這一組（選型理由，值得讀）

**① 為何 `pg` 而不是 `postgres.js`。** `pg` 的連線池是**顯式**的——
`new Pool({ max: 10 })`、`client.release()` 你都看得見。本課要教「連線是有限資源」
（2.1.5），用看得見的 API 才教得出來；把池藏起來的套件學不到這件事。

**② 為何 TypeScript 5.9.3 而不是最新的 7.x。** TS 7 能跑（實測過），但生態、教學文章、
Stack Overflow 答案都還沒跟上。**這門課的重點不是 TS 新特性,是排程邏輯**——
卡在工具鏈上的每一小時都是從業務邏輯偷來的。同理選 PG 17 而非 18。

**③ 為何 React 18 + Refine 4 而不是 React 19 + Refine 5。** 兩組都實測可用，但
React 18 + Refine 4 + antd 5 是目前教學資源覆蓋最厚的組合。**版本一致與查得到答案，
比版本新重要。**

**④ 為何 zod 3 而不是 4。** 與上述同代生態對齊；zod 4 的 API 有變動，範例與教學多數
仍是 3.x。

> **`bun.lock` 必須進版控。** 它才是「環境可重現」的唯一真相——助教在自己機器上
> `bun install` 必須還原出與你完全相同的版本樹。

##### 升級守則

課程期間**不要升級**。真要升，一次只升一個套件，且升完必須：
`bun install` → `bun test` → `tsc --noEmit` → `vite build` **四項全綠**才算數。
升級後 `bun.lock` 一起 commit。

### 2.2 工廠結構（Factory Structure）

| 編號             | 內容                                                                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **FACT-1** | 公司營運多個生產據點（Production Sites）                                                                                             |
| **FACT-2** | 生產據點以多個每週週期（Weekly Cycles）運作；一個每週週期以日曆週次（calendar week）與年份（year）依 ISO 8601 標準辨識               |
| **FACT-3** | 操作員為特定的生產據點與週次進行登記                                                                                                 |
| **FACT-4** | 每個週次包含「產品＋製程（Product+Process）」組合的生產任務（Production Tasks），可透過 CSV 或手動輸入提供；產品具有名稱且不可硬編碼 |
| **FACT-5** | 生產據點由一個或多個據點主管（Site Managers）管理                                                                                    |
| **FACT-6** | 工作站（Work Stations）位於據點內部，並由其與製程關聯的技術能力（Technical Capabilities）所定義                                      |
| **FACT-7** | 排程僅允許於週一至週五的 06:00 至 18:00 之間                                                                                         |

### 2.3 生產任務（Production Tasks）

| 編號              | 內容                                                                                                |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| **TASK-1**  | 任務是「產品」與「製程」的組合。產品可以任意順序進行處理                                            |
| **TASK-2**  | 每一個製程都與一個給操作員的「證照（Certification）」以及一個給工作站的「能力（Capability）」相關聯 |
| **TASK-3**  | **能力匹配（Capability Match）**：任務只能被指派給具備該製程所需技術能力的工作站              |
| **TASK-4**  | **證照檢查（Certification Check）**：任務只能被指派給持有所需證照的操作員                     |
| **TASK-5**  | 任務必須排定給單一一位操作員與單一一個工作站                                                        |
| **TASK-6**  | 在同一據點且同一時間的任務，於工作站或人員使用上不可重疊                                            |
| **TASK-7**  | 任務不可超過 6 小時，且持續時間必須是 5 分鐘的倍數；任務必須在同一天內開始與結束                    |
| **TASK-8**  | 任務可處於「In Planning（規劃中）」、「Scheduled（已排程）」或「Finished（已完成）」三種狀態        |
| **TASK-9**  | 每一個任務都有一個指定的生產據點，且只能在該據點被排程                                              |
| **TASK-10** | 一旦完全排程完成，任務的工作站與時間就不可再變更                                                    |

### 2.4 使用者群組（User Groups）

存在多種使用者群組：管理員（Administrators）、據點主管（Site Managers）、操作員（Operators）以及匿名使用者（Anonymous Users）。權限落法見 2.1.4 權限矩陣。

#### 2.4.1 一般「人員（Persons）」共通規定

| 編號             | 內容                                                                             |
| ---------------- | -------------------------------------------------------------------------------- |
| **PERS-1** | 所有人員（persons）都有名字（first name）、姓氏（last name）以及一個電子郵件地址 |
| **PERS-2** | 人員以電子郵件地址與密碼登入（密碼以 argon2id 雜湊儲存，見 TECH-9）              |

#### 2.4.2 管理員（Administrators）

| 編號             | 內容                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------- |
| **PERS-3** | 管理員必須登入系統                                                                       |
| **PERS-4** | 只有管理員能存取**管理介面**（Refine admin 資源頁：users / sites / certifications / capabilities 的 CRUD；`accessControlProvider` 擋前端、路由守衛擋後端，非管理員一律 403） |
| **PERS-5** | 管理員可檢視並修改所有資料（使用者、據點、能力）                                         |
| **PERS-6** | 管理員可新增使用者，並管理「證照（Certifications）」與「能力（Capabilities）」的全域清單 |

#### 2.4.3 據點主管（Site Managers）

| 編號              | 內容                                                                                                   |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| **PERS-7**  | 據點主管必須登入                                                                                       |
| **PERS-8**  | 被指派到特定的生產據點                                                                                 |
| **PERS-9**  | 為其所屬據點，透過組合「產品」與「製程」來建立任務                                                     |
| **PERS-10** | 透過將證照與能力對應到製程的需求，把操作員與工作站指派到所需的時段中                                   |
| **PERS-11** | 操作員必須登記同一據點與同一週次，才能被指派到任務                                                     |
| **PERS-12** | 據點主管僅能管理其所負責據點的任務與排程                                                               |
| **PERS-13** | 可檢視其所屬據點所有任務的狀態（In Planning、Scheduled、Finished）                                     |
| **PERS-14** | 將任務規劃定案（finalize），並鎖定每週排程                                                             |
| **PERS-15** | 可匯入下列項目的 CSV 上傳：工人（workers）的據點登記及其證照、工作站及其能力、每週每據點所需的生產任務 |

#### 2.4.4 操作員（Operators）

| 編號              | 內容                                                               |
| ----------------- | ------------------------------------------------------------------ |
| **PERS-16** | 操作員必須登入                                                     |
| **PERS-17** | 僅能檢視其所登記據點與週次中已完全排程的任務                       |
| **PERS-18** | 可依「據點」與「週次」篩選任務                                     |
| **PERS-19** | 為一個據點與週次進行登記；可依其持有的證照檢視自身有資格承接的任務 |
| **PERS-20** | 任務完成後，將其被指派的任務標記為「Finished」                     |
| **PERS-21** | 檢視自己的「已完成任務」歷史紀錄與目前持有的證照                   |
| **PERS-22** | 無法檢視其他操作員的詳細工作狀態                                   |

#### 2.4.5 匿名使用者（Anonymous Users）

| 編號              | 內容                                                             |
| ----------------- | ---------------------------------------------------------------- |
| **PERS-23** | 匿名使用者為未登入狀態                                           |
| **PERS-24** | 可看見生產據點的已排程任務，但操作員姓名須被匿名化（anonymized；匿名化在**後端**查詢層完成，前端拿不到原始姓名） |
| **PERS-25** | 可依「生產據點」與「週次」篩選任務                               |

### 2.5 驗收條件（Acceptance Criteria）

| 編號            | 內容                                                                                                        |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| **ACC-1** | 透過匯入一份主要的測試資料集（primary test dataset，置於 `testdata/`）來展示功能                            |
| **ACC-2** | 該資料集需包含 2 個以上的據點、2 個以上的每週週期，以及每週 3 個以上的任務                                  |
| **ACC-3** | 該資料集需包含至少三種製程類型、至少兩種證照，以及至少兩種工作站能力                                        |
| **ACC-4** | 第二份包含 1,000 個任務的測試資料集會被自動匯入。手動新增一個額外任務時，不可因資料量而出現可察覺的速度變慢 |
| **ACC-5** | 使用者介面（UI）以 **Ant Design 元件庫**達到最低限度的可用性（表格/表單/週曆檢視皆用現成元件，不手刻）      |
| **ACC-6** | **斷網驗收**：在完全無網路的環境下展示全部功能；瀏覽器 DevTools Network 面板不得出現任何外部網域請求（TECH-12） |
| **ACC-7** | **Compose 驗收**：於單機 Docker Desktop 上，照 README 四步（`docker load` → 設 `.env` → `docker compose up -d` → 開瀏覽器）啟動並走完附錄 C Demo 劇本；重建容器（`down`/`up`）後資料仍在（**具名 volume 驗證**） |

---

## 3. 範圍限制（Scope Limitations）

有些問題不在本專案的範圍內，為了簡化處理可以略過：

| 編號             | 內容                                                                     |
| ---------------- | ------------------------------------------------------------------------ |
| **EXCL-1** | 最佳化的排程演算法：系統僅驗證衝突，並不計算最佳排程                     |
| **EXCL-2** | 報表功能（KPI、稼動率儀表板等）不在範圍內                                |
| **EXCL-3** | 證照不會過期，且工作站不會因為維護而離線                                 |
| **EXCL-4** | 本系統不需實際寄送電子郵件                                               |
| **EXCL-5** | 庫存追蹤（Inventory tracking）與物料耗用不在範圍內                       |
| **EXCL-6** | 超出「每週登記」模式之外的操作員班別規則（例如加班、輪班輪替）不在範圍內 |

以上這些元素「可以」被實作，但並非必要。

---

## 附錄 A：里程碑與評分（教學用）

六個里程碑，每個都有**可展示的產出**；驗收＝逐條需求打勾。M＝必要、S＝加分。
（與 V2 版同一套骨架，僅實作載體不同。）

| 里程碑 | 產出（可 demo） | 對應需求 | 等級 |
|---|---|---|---|
| **M1** | compose 起 db + migrations + admin 資源頁（Refine Inferencer 起手）：產品/製程/證照/能力/據點/工作站 CRUD | TECH-11, PERS-4~6 | M |
| **M2** | 登入（JWT httpOnly cookie）+ accessControlProvider 四角色骨架（未授權=403） | PERS-1~3, 7, 16, 23 | M |
| **M3** | 操作員登記（據點×週次）+ 主管建任務 | FACT-3, PERS-9~11, 19 | M |
| **M4** | **排程指派＋衝突檢核 service**（本專案的心臟：能力/證照/重疊/時窗）＋ **`EXCLUDE` 約束並行測試** | TASK-3~7, FACT-7 | M |
| **M5** | CSV 匯入 + 公開看板（匿名化 SQL 模板） | PERS-15, 24~25 | M |
| **M6** | 千筆效能 + 斷網驗收 + `bun test` 補齊 | ACC-4, ACC-6, TECH-8 | M |
| S | 週曆視覺化、Casbin 整合、finalize 鎖定 UX 等 | PERS-14 等 | S |

**評分原則**：①逐條需求打勾（佔大宗）；②commit 歷史看得出里程碑節奏（防最後一天一包 zip）；
③M4 衝突檢核必須有單元測試才算過；④每條 SQL 模板的 `source:` 能反查到需求編號（2.1.7 鐵律 1）。

## 附錄 B：踩坑地圖（開工前先讀，撞到再回來對號入座）

**共通坑（不分技術棧）**：
1. **ISO 8601 週次**：一年可能有 53 週；1/1 可能屬於「去年第 52 週」——TS 沒有內建
   isocalendar，**自己手算必錯**；寫一個 `isoWeek()` 工具函式並先寫測試（12/31、1/1、閏年）。
2. **排程 race condition**：兩請求同時指派同一工作站——服務層檢查會雙雙通過；
   **資料庫層約束才是底**（`EXCLUDE USING gist`，見 2.1.5）。換成真 PG 後這件事
   **真的重現得出來**，也**真的測得到**——並行測試是必要項，不是選配。
3. **CSV 編碼**：Excel 存的 CSV 是 CP950 不是 UTF-8——匯入端須偵測或明訂編碼並給清楚錯誤（TECH-10）。
4. **匿名化的位置**：在前端藏名字＝沒藏（API 回應裡看得到）——必須在 **SQL 層**就以別名輸出
   （見 2.1.7 範例的 `dense_rank()`），API 從頭到尾不含真名（PERS-24）。

**TS 全棧專屬坑**：
5. **Date 與時區**：JS `Date` 的隱式本地時區轉換是災難源——時刻一律存 ISO 字串或
   epoch，比較用數值；顯示層才格式化。
6. **連線池耗盡**：每個請求開一條新連線而不歸還 ⇒ 跑一陣子就 `too many connections`
   或整個卡住。一律用 `db/pool.ts` 的池單例；查完務必歸還（用完即釋放,別把連線
   抓在手上做慢事）。測試**禁連正式庫**,一律 `fms_test` + 各自 schema（2.1.6）。
7. **cookie 跨埠**：vite 5173 → 後端 3000，cookie 要走 vite proxy（同源化）才收得到;
   直接 fetch `http://localhost:3000` 會掉 cookie（CORS + credentials 雙坑）。
8. **Refine 只擋 UX**：`accessControlProvider` 擋掉按鈕≠安全——後端每個端點都要有
   自己的角色守衛（2.1.4 鐵律：前端擋 UX、後端擋安全）。
9. **PG 還沒 ready 就連線**：`depends_on` 只等「容器啟動」,不等「PG 可接受連線」——
   第一次 `compose up` 十之八九是 backend 先撞牆。解法是 `healthcheck` +
   `condition: service_healthy`（2.1.9 規範 3）。
10. **`docker compose down -v` 手滑**：`-v` 會連 volume 一起刪,資料全沒。
    平常用 `down` 就好;真要清庫再加 `-v`,而且想一下再按 Enter。
11. **`bun add antd` 會裝到不相容的 antd 6（★最陰險的一坑）**：
    `@refinedev/antd@5.47.0` 的 peer 要求是 `antd ^5.x`,但 antd 最新已是 6.x——
    **Bun 對 peer 不相容不會報錯,直接裝下去**。更糟的是它**還 render 得出來**,
    看起來一切正常,直到某個元件在某個情境炸掉,而你完全不知道為什麼。
    解法:`package.json` 寫死 `"antd": "5.29.3"`（不加 `^`）,別打 `bun add antd`。
    **版本鎖定表見 2.1.11。**
12. **`@tanstack/react-query` 漏裝**：它是 Refine 明列的 peer,但**不會被自動安裝**——
    漏了不會在 install 時報錯,而是**執行期**才爆。照 2.1.11 表把它列進 `package.json`。

## 附錄 C：Demo 劇本（10 分鐘驗收走位；學員自測與老師抽查同一份）

與 V2 版**完全同一份劇本**（同需求同流程）：
1. admin 登入 → 建 2 據點/3 製程/2 證照/2 能力（M1）
2. 操作員 A 登記「據點1×第 N 週」；操作員 B 不登記（M3）
3. 主管建任務→指派：選 B ⇒ **被擋**（PERS-11）；選無證照者 ⇒ 被擋（TASK-4）；選錯能力工作站 ⇒ 被擋（TASK-3）
4. 正確指派 A ⇒ Scheduled；再排同時段同工作站 ⇒ **衝突被擋**（TASK-6）
5. 排 19:00 或週六 ⇒ 被擋（FACT-7）；排 6.5 小時 ⇒ 被擋（TASK-7）
6. 操作員 A 登入 → 只看到自己已排程任務 → 標記 Finished（PERS-17, 20）
7. 登出 → 匿名開公開看板 → 看得到任務、**看不到真名**（PERS-24）
8. 匯入千筆集 → 手動再建一筆任務,無可察覺變慢（ACC-4）
9. 全程斷網,DevTools Network 零外部請求（ACC-6）

## 附錄 D：V2 ↔ V3 對照（同一份需求，兩個世代的實作）

| 面向 | V2 | V3（本版） |
|---|---|---|
| 語言/框架 | Python + Django（伺服端渲染） | TypeScript + Bun + Elysia + Refine（SPA） |
| UI | AdminLTE（Bootstrap，template 渲染） | Ant Design（React 元件） |
| 管理介面 | Django admin（**約定即得**） | Refine resources + accessControlProvider（**顯式接**） |
| 資料庫 | SQLite（Django ORM） | **PostgreSQL 17 伺服器**（Docker,連線池 + SQL 模板） |
| 驗證 | Django Forms / `clean()` | Elysia `t` + Zod 雙層 |
| 測試 | Django `TestCase` | `bun test` + 每檔獨立 PG schema |
| 教學重點 | MVC、ORM、約定優於配置 | 型別安全全棧、REST 契約、顯式權限模型 |

> 兩版功能需求（FACT/TASK/PERS/ACC）編號完全相同——上完 V2 再看 V3，
> 學的是「同一個問題，框架世代如何改變解法」。

---

*v3.1（2026-08-25）：技術棧由 Python/Django/SQLite 改版為 TypeScript 全棧（Bun + Elysia + PGlite + Refine + Ant Design）；功能需求（FACT/TASK/PERS/ACC/EXCL）與原版一致，編號不變。*
*v3.2（2026-08-25）：TECH-12 離線鐵律/ACC-6 斷網驗收；新增附錄 A~D（里程碑評分/踩坑地圖/Demo 劇本/版本對照），與 V2 版同步骨架、各自技術細節。*
*v3.3（2026-08-25）：資料庫由 **PGlite（嵌入式）改為 PostgreSQL 17 伺服器**（映像 `pgvector/pgvector:0.8.6-pg17`，Compose `db` 服務）——理由與實戰取捨見 2.1.5；連動更新 TECH-3/4/5/7/12、2.1.1 架構、2.1.2 選型、2.1.3 結構、2.1.6 測試隔離（每檔一個 schema）、2.1.9 部署（三服務＋healthcheck＋離線四件套）、ACC-7、附錄 A M1/M4、附錄 B 坑 2/6/9/10、附錄 D；新增 2.1.10 未來擴充路線（ETL→資料倉儲、pgvector、WrenAI；**不列入驗收**）。功能需求（FACT/TASK/PERS/ACC/EXCL）編號不變。*
*v3.4（2026-08-25）：新增 **2.1.11 版本鎖定表**（Bun 1.4.0 / Elysia 1.4.29 / pg 8.23.0 / zod 3.25.76 / TS 5.9.3 / React 18.3.1 / antd 5.29.3 / Refine 4.58 / Vite 6.4.3）——以既有生產專案的版本線為基準,經 2026-08-25 實測核實（後端 7/7、前端 2/2 測試通過,前後端 tsc 0 error,vite build 成功）;DB 驅動由 postgres.js 改為 **pg**（顯式連線池,教學考量）;TECH-1 鎖版;2.1.2 選型表補版本;附錄 B 新增坑 11（antd peer 靜默不相容）與坑 12（react-query peer 漏裝）。功能需求編號不變。*
*v3.5（2026-08-25）：repo 附**開發期環境** `infra/`（`docker-compose.yml`：db＝PostgreSQL 17 + pgvector、minio＝S3 相容儲存,為將來 ETL/檔案上傳預留;附 `.env.example` 與 `README.md`）,學員 `cd infra && docker compose up -d` 即有資料庫,不必手動安裝——**`infra/` 是環境不是交付物**,交付形態的三服務 compose 由學員自寫於專案根目錄（ACC-7 驗那一份）,兩份分開放;2.1.3 結構補 `infra/` 與 `db/init/`;2.1.4 新增「為何不採資料表驅動 RBAC」的取捨說明（列為加分題,鐵律仍是前端擋 UX、後端擋安全）。功能需求編號不變。*
*v3.6（2026-08-25）：`infra/` compose **實測核實**（Docker 29.5.3 / Compose v5.1.4, WSL2）：兩服務皆 healthy、PG 17.11、pgvector 0.8.6 + btree_gist 1.7 可用、`down`/`up` 資料保留、`db/init/` 自動執行;**2.1.5 的 `EXCLUDE USING gist` 約束與並行 race 實測通過**（重疊擋下 23P01、邊界接續通過、Finished 部分索引生效、兩連線同搶恰好一條成功）;修正一處與實測不符的敘述:`backend/` 不存在時掛載**不會**報錯（Docker 自動建空目錄）。功能需求編號不變。*
