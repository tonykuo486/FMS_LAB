# 課程指引（Course Guide）：FMS_V3

**Factory Management System — TypeScript 全棧版** ｜ v1.0（2026-08-25）

> **這份文件回答「怎麼學」。** 需求（做什麼）見 [`SRS.md`](SRS.md)；
> 設計（怎麼做）見 [`SDD.md`](SDD.md)。

| | 全名 | 內容 |
|---|---|---|
| [SRS.md](SRS.md) | Software Requirements Specification | 需求（做什麼）——逐條驗收 |
| [SDD.md](SDD.md) | Software Design Document | 設計（怎麼做）——架構與技術決策 |
| **GUIDE.md**（本檔） | Course Guide | 教學（怎麼學）——里程碑、踩坑地圖 |

## 怎麼用這三份文件

```
開工前 ── 讀 SRS 第 2 章(每條編號都是驗收項)
            ↓
         讀 GUIDE 附錄 B 踩坑地圖(★先讀,能省好幾小時)
            ↓
         讀 SDD §11 版本鎖定表 → 照抄 package.json
            ↓
實作中 ── 照 GUIDE 里程碑 M1~M6 推進
            ↓  每個里程碑遇到技術問題 → 查 SDD 對應章節
            ↓
驗收前 ── 照 SRS 附錄 Demo 劇本自測一遍(老師抽查同一份)
```

---

## 1. 里程碑與評分

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
③M4 衝突檢核必須有單元測試才算過；④每條 SQL 模板的 `source:` 能反查到需求編號（[SDD §7](SDD.md) 鐵律 1）。

## 2. 踩坑地圖（開工前先讀，撞到再回來對號入座）

**共通坑（不分技術棧）**：
1. **ISO 8601 週次**：一年可能有 53 週；1/1 可能屬於「去年第 52 週」——TS 沒有內建
   isocalendar，**自己手算必錯**；寫一個 `isoWeek()` 工具函式並先寫測試（12/31、1/1、閏年）。
2. **排程 race condition**：兩請求同時指派同一工作站——服務層檢查會雙雙通過；
   **資料庫層約束才是底**（`EXCLUDE USING gist`，見 [SDD §5](SDD.md)）。換成真 PG 後這件事
   **真的重現得出來**，也**真的測得到**——並行測試是必要項，不是選配。
3. **CSV 編碼**：Excel 存的 CSV 是 CP950 不是 UTF-8——匯入端須偵測或明訂編碼並給清楚錯誤（TECH-10）。
4. **匿名化的位置**：在前端藏名字＝沒藏（API 回應裡看得到）——必須在 **SQL 層**就以別名輸出
   （見 [SDD §7](SDD.md) 範例的 `dense_rank()`），API 從頭到尾不含真名（PERS-24）。

**TS 全棧專屬坑**：
5. **Date 與時區**：JS `Date` 的隱式本地時區轉換是災難源——時刻一律存 ISO 字串或
   epoch，比較用數值；顯示層才格式化。
6. **連線池耗盡**：每個請求開一條新連線而不歸還 ⇒ 跑一陣子就 `too many connections`
   或整個卡住。一律用 `db/pool.ts` 的池單例；查完務必歸還（用完即釋放,別把連線
   抓在手上做慢事）。測試**禁連正式庫**,一律 `fms_test` + 各自 schema（[SDD §6](SDD.md)）。
7. **cookie 跨埠**：vite 5173 → 後端 3000，cookie 要走 vite proxy（同源化）才收得到;
   直接 fetch `http://localhost:3000` 會掉 cookie（CORS + credentials 雙坑）。
8. **Refine 只擋 UX**：`accessControlProvider` 擋掉按鈕≠安全——後端每個端點都要有
   自己的角色守衛（[SDD §4](SDD.md) 鐵律：前端擋 UX、後端擋安全）。
9. **PG 還沒 ready 就連線**：`depends_on` 只等「容器啟動」,不等「PG 可接受連線」——
   第一次 `compose up` 十之八九是 backend 先撞牆。解法是 `healthcheck` +
   `condition: service_healthy`（[SDD §9](SDD.md) 規範 3）。
10. **`docker compose down -v` 手滑**：`-v` 會連 volume 一起刪,資料全沒。
    平常用 `down` 就好;真要清庫再加 `-v`,而且想一下再按 Enter。
11. **`bun add antd` 會裝到不相容的 antd 6（★最陰險的一坑）**：
    `@refinedev/antd@5.47.0` 的 peer 要求是 `antd ^5.x`,但 antd 最新已是 6.x——
    **Bun 對 peer 不相容不會報錯,直接裝下去**。更糟的是它**還 render 得出來**,
    看起來一切正常,直到某個元件在某個情境炸掉,而你完全不知道為什麼。
    解法:`package.json` 寫死 `"antd": "5.29.3"`（不加 `^`）,別打 `bun add antd`。
    **版本鎖定表見 [SDD §11](SDD.md)。**
12. **`@tanstack/react-query` 漏裝**：它是 Refine 明列的 peer,但**不會被自動安裝**——
    漏了不會在 install 時報錯,而是**執行期**才爆。照 [SDD §11](SDD.md) 表把它列進 `package.json`。

## 3. V2 / V3 對照（同一份需求，兩個世代的實作）

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
*v3.3（2026-08-25）：資料庫由 **PGlite（嵌入式）改為 PostgreSQL 17 伺服器**（映像 `pgvector/pgvector:0.8.6-pg17`，Compose `db` 服務）——理由與實戰取捨見 [SDD §5](SDD.md)；連動更新 TECH-3/4/5/7/12、[SDD §1](SDD.md) 架構、[SDD §2](SDD.md) 選型、[SDD §3](SDD.md) 結構、[SDD §6](SDD.md) 測試隔離（每檔一個 schema）、[SDD §9](SDD.md) 部署（三服務＋healthcheck＋離線四件套）、ACC-7、附錄 A M1/M4、附錄 B 坑 2/6/9/10、附錄 D；新增 [SDD §10](SDD.md) 未來擴充路線（ETL→資料倉儲、pgvector、WrenAI；**不列入驗收**）。功能需求（FACT/TASK/PERS/ACC/EXCL）編號不變。*
*v3.4（2026-08-25）：新增 **[SDD §11](SDD.md) 版本鎖定表**（Bun 1.4.0 / Elysia 1.4.29 / pg 8.23.0 / zod 3.25.76 / TS 5.9.3 / React 18.3.1 / antd 5.29.3 / Refine 4.58 / Vite 6.4.3）——以既有生產專案的版本線為基準,經 2026-08-25 實測核實（後端 7/7、前端 2/2 測試通過,前後端 tsc 0 error,vite build 成功）;DB 驅動由 postgres.js 改為 **pg**（顯式連線池,教學考量）;TECH-1 鎖版;[SDD §2](SDD.md) 選型表補版本;附錄 B 新增坑 11（antd peer 靜默不相容）與坑 12（react-query peer 漏裝）。功能需求編號不變。*
*v3.5（2026-08-25）：repo 附**開發期環境** `infra/`（`docker-compose.yml`：db＝PostgreSQL 17 + pgvector、minio＝S3 相容儲存,為將來 ETL/檔案上傳預留;附 `.env.example` 與 `README.md`）,學員 `cd infra && docker compose up -d` 即有資料庫,不必手動安裝——**`infra/` 是環境不是交付物**,交付形態的三服務 compose 由學員自寫於專案根目錄（ACC-7 驗那一份）,兩份分開放;[SDD §3](SDD.md) 結構補 `infra/` 與 `db/init/`;[SDD §4](SDD.md) 新增「為何不採資料表驅動 RBAC」的取捨說明（列為加分題,鐵律仍是前端擋 UX、後端擋安全）。功能需求編號不變。*
*v3.6（2026-08-25）：`infra/` compose **實測核實**（Docker 29.5.3 / Compose v5.1.4, WSL2）：兩服務皆 healthy、PG 17.11、pgvector 0.8.6 + btree_gist 1.7 可用、`down`/`up` 資料保留、`db/init/` 自動執行;**[SDD §5](SDD.md) 的 `EXCLUDE USING gist` 約束與並行 race 實測通過**（重疊擋下 23P01、邊界接續通過、Finished 部分索引生效、兩連線同搶恰好一條成功）;修正一處與實測不符的敘述:`backend/` 不存在時掛載**不會**報錯（Docker 自動建空目錄）。功能需求編號不變。*
