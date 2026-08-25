# 需求規格書（Lastenheft）：工廠管理系統（Factory Management System）

**程式設計專題 WI（Programming Project WI）** ｜ v2.3（2026-08-25）：UI 採 **AdminLTE**；套件管理採 **uv**


## 1. 概述（Overview）

工廠需要軟體來在多個據點之間排程生產任務。其挑戰特別包含：排程（scheduling）與工作站分配（work station allocation）。本專案要實作一套工廠管理系統，讓據點主管（site managers）能更輕鬆地規劃任務，並提供操作員（operators）一個簡易的方式來檢視並登記不同生產據點的每週班次。

生產規劃的工作流程依照以下步驟進行。在一個每週生產週期開始時，「產品（Products）」及其各自的「製程（Processes）」會被確認定案。操作員會針對特定的「生產據點（Production Sites）」與「週次（Weeks）」進行登記。據點主管依據這些登記，透過將產品與特定製程組合來決定任務（task）的指派。每一項任務都會分配一個工作站（work station）與一個時段（time slot），以確保：避免排程衝突、操作員持有該製程所需的證照（certification）、且工作站具備該製程所需的技術能力（technical capability）。任務完成後，操作員將該任務標記為「Finished（已完成）」，讓據點主管能夠監控進度與完成狀態。

詳細需求列於第 2 章。第 3 章描述不屬於本專案範圍，因此不需要被實作的元素。

---

## 2. 需求（Requirements）

### 2.1 技術規格（Technical Specifications）

| 編號              | 內容                                                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **TECH-1**  | 實作語言為 Python 3；**套件與虛擬環境一律以 [uv](https://docs.astral.sh/uv/) 管理**（`uv sync` 還原環境、`uv run` 執行；不使用裸 pip/venv） |
| **TECH-2**  | Web 框架：Django                                                                                                                      |
| **TECH-3**  | 持久性資料儲存於一個 SQL 資料庫                                                                                                       |
| **TECH-4**  | 可以使用 Django 提供的 SQLite 資料庫；不需要外部資料庫                                                                                |
| **TECH-5**  | **開發期**可使用 Django 開發用 Web 伺服器；**交付與驗收必須以 Docker Compose 啟動**（見 TECH-13）                                       |
| **TECH-6**  | 使用者介面以 **Django Templates + AdminLTE**（Bootstrap 底）實作，產出語法正確的 HTML5/CSS（版型規範見 2.1.1）                          |
| **TECH-7**  | 程式碼必須能在 Windows、macOS 與 Linux 上執行                                                                                         |
| **TECH-8**  | 程式碼必須以單元測試（unit tests）加以保護                                                                                            |
| **TECH-9**  | 所有使用者輸入都必須經過驗證，以防範 CSRF、程式碼注入（code injection）與未授權存取                                                   |
| **TECH-10** | 語意上不正確的使用者輸入必須以清楚的錯誤訊息加以拒絕                                                                                  |
| **TECH-11** | 系統必須具備可調整性（adaptable）；產品（products）、製程（processes）、證照（certifications）與據點（sites）不可硬編碼（hard-coded） |
| **TECH-12** | **完全離線可用，禁用任何 CDN**：所有前端資產（AdminLTE、Bootstrap、jQuery、圖示字型）一律 vendor 進 repo（`static/lib/`）；字型用系統字型堆疊（system font stack），**不得引用 Google Fonts**；Python 套件以 **uv** 離線安裝：`pyproject.toml` + **`uv.lock` 為唯一真相**，預先 `uv export --format requirements-txt > requirements.txt` 並 `uv pip download -d wheels/ -r requirements.txt` 備妥本地 wheelhouse，教室機 `uv pip install --offline --no-index --find-links wheels/ -r requirements.txt` |
| **TECH-13** | **必須能以 Docker Compose 部署於單機**（Docker Desktop）：repo 附 `Dockerfile` + `docker-compose.yml`，`docker compose up -d` 一鍵啟動即可使用；**build 過程零外網**（依賴走 TECH-12 的 uv wheelhouse），基底映像以 `docker save`/`docker load` 預載（部署規格見 2.1.2） |

#### 2.1.1 UI 版型規範（AdminLTE）

採 **AdminLTE 3.2**（Bootstrap 4.6 底；資產放 `static/lib/adminlte/`，離線可用、不依賴 CDN）。
所有頁面套同一版型，**不得混用其他 CSS 框架**：

| 區塊 | AdminLTE 落法 |
|---|---|
| 整體版型 | 標準 Admin 版型：頂部 `main-header navbar` + 左側 `main-sidebar sidebar-dark-primary` + `content-wrapper` |
| 左側選單 | `nav-sidebar` 依角色分群渲染（Django template 依 `request.user` 角色判斷）：任務排程（主管）／我的班表（操作員）／公開看板（所有人）／系統管理（僅管理員，連 Django admin） |
| 側欄底部 | 登入者姓名＋角色＋所屬據點；登出連結 |
| 內容區 | 一律用 `card`（`card-header` 放標題與工具鈕、`card-body` 放表格/表單）；清單用 `table table-striped table-hover` |
| 頁內分類切換 | `nav nav-pills`（膠囊式，不用底線 tabs） |
| 登入頁 | AdminLTE `login-page` + `login-box` 版型（置中卡片；錯誤訊息具體但不揭露帳號是否存在） |
| 狀態顯示 | 任務狀態以 `badge` 呈現：In Planning=`badge-secondary`、Scheduled=`badge-primary`、Finished=`badge-success` |
| 表單驗證 | Django form errors 對接 Bootstrap `is-invalid` + `invalid-feedback`（TECH-10 清楚錯誤訊息） |
| RWD | 沿用 AdminLTE 內建行為：窄屏側欄自動收合為抽屜（漢堡鈕） |

> 選配：品牌主色可覆寫為鋼藍 `#2E6DA4`（自訂一支 `custom.css` 覆蓋 `.btn-primary`/
> `.sidebar-dark-primary .nav-link.active`），非必要項。

#### 2.1.2 Docker Compose 部署規格（TECH-13）

單機（Docker Desktop）、單服務即可：

```yaml
# docker-compose.yml
services:
  web:
    build: .                       # Dockerfile：FROM python:3.12-slim
    ports: ["8000:8000"]
    volumes:
      - ./data:/app/data           # ★SQLite 檔放 volume——容器重建資料不丟
    command: sh -c "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"
```

```dockerfile
# Dockerfile（離線 build：不打 PyPI；uv 由官方映像 COPY 進來，不走網路安裝）
FROM python:3.12-slim
# uv 二進位（單一執行檔，無相依）——教室機需先 docker load 這個映像
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
COPY wheels/ wheels/
COPY pyproject.toml uv.lock requirements.txt ./
# --offline：確保 build 期零外網;命中不了 wheelhouse 就讓它失敗,不要偷連 PyPI
RUN uv pip install --system --offline --no-index --find-links wheels/ -r requirements.txt
COPY . .
```

**規範**：
1. `settings.py` 的資料庫路徑指向 `/app/data/db.sqlite3`（volume 內），**禁**放容器層。
2. **離線三件套**：基底映像預載（`docker save python:3.12-slim ghcr.io/astral-sh/uv:latest
   -o base.tar` → 教室機 `docker load`）＋ **uv wheelhouse**（`wheels/` 進 build context，
   由 `uv.lock` 匯出）＋ `static/lib/` 已 vendor——三者齊備即可斷網
   `docker compose up --build`。
   > 為何用 uv 而非 pip：`uv.lock` 鎖定**跨平台可重現**的完整相依樹（含 hash），
   > 三十位學員機器還原出的環境一模一樣;`uv sync` 亦比 pip 快一個量級，
   > 教室現場等待時間差很有感。
3. 課程接受 `runserver` 於容器內作為交付形態（單機教學用）；改 gunicorn 列加分項。
4. 驗收指令即文件：README 須含「`docker load` → `docker compose up -d` → 開
   `http://localhost:8000`」三步，照打即通（ACC-7）。

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

存在多種使用者群組：管理員（Administrators）、據點主管（Site Managers）、操作員（Operators）以及匿名使用者（Anonymous Users）。

#### 2.4.1 一般「人員（Persons）」共通規定

| 編號             | 內容                                                                             |
| ---------------- | -------------------------------------------------------------------------------- |
| **PERS-1** | 所有人員（persons）都有名字（first name）、姓氏（last name）以及一個電子郵件地址 |
| **PERS-2** | 人員以電子郵件地址與密碼登入                                                     |

#### 2.4.2 管理員（Administrators）

| 編號             | 內容                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------- |
| **PERS-3** | 管理員必須登入系統                                                                       |
| **PERS-4** | 只有管理員能存取 Django 內建的管理介面                                                   |
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
| **PERS-24** | 可看見生產據點的已排程任務，但操作員姓名須被匿名化（anonymized） |
| **PERS-25** | 可依「生產據點」與「週次」篩選任務                               |

### 2.5 驗收條件（Acceptance Criteria）

| 編號            | 內容                                                                                                        |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| **ACC-1** | 透過匯入一份主要的測試資料集（primary test dataset）來展示功能                                              |
| **ACC-2** | 該資料集需包含 2 個以上的據點、2 個以上的每週週期，以及每週 3 個以上的任務                                  |
| **ACC-3** | 該資料集需包含至少三種製程類型、至少兩種證照，以及至少兩種工作站能力                                        |
| **ACC-4** | 第二份包含 1,000 個任務的測試資料集會被自動匯入。手動新增一個額外任務時，不可因資料量而出現可察覺的速度變慢 |
| **ACC-5** | 使用者介面（UI）以 **AdminLTE**（Bootstrap 底）達到最低限度的可用性；全站同一版型（見 2.1.1），不混框架        |
| **ACC-6** | **斷網驗收**：在完全無網路的環境下展示全部功能；瀏覽器 DevTools Network 面板不得出現任何外部網域請求（TECH-12） |
| **ACC-7** | **Compose 驗收**：於單機 Docker Desktop 上，照 README 三步（`docker load` → `docker compose up -d` → 開瀏覽器）啟動並走完附錄 C Demo 劇本；重建容器（`down`/`up`）後資料仍在（volume 驗證） |

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

| 里程碑 | 產出（可 demo） | 對應需求 | 等級 |
|---|---|---|---|
| **M1** | Models + Django admin：產品/製程/證照/能力/據點/工作站 CRUD | TECH-11, PERS-4~6 | M |
| **M2** | 登入 + 四角色權限骨架（未授權=403） | PERS-1~3, 7, 16, 23 | M |
| **M3** | 操作員登記（據點×週次）+ 主管建任務 | FACT-3, PERS-9~11, 19 | M |
| **M4** | **排程指派＋衝突檢核**（本專案的心臟：能力/證照/重疊/時窗） | TASK-3~7, FACT-7 | M |
| **M5** | CSV 匯入 + 公開看板（匿名化） | PERS-15, 24~25 | M |
| **M6** | 千筆效能 + 斷網驗收 + 單元測試補齊 | ACC-4, ACC-6, TECH-8 | M |
| S | 週曆視覺化、Casbin/進階權限、finalize 鎖定 UX 等 | PERS-14 等 | S |

**評分原則**：①逐條需求打勾（佔大宗）；②commit 歷史看得出里程碑節奏（防最後一天一包 zip）；
③M4 衝突檢核必須有單元測試才算過（TECH-8 在此驗真）。

## 附錄 B：踩坑地圖（開工前先讀，撞到再回來對號入座）

**共通坑（不分技術棧）**：
1. **ISO 8601 週次**：一年可能有 53 週；1/1 可能屬於「去年第 52 週」——用 `date.isocalendar()`，自己算必錯（FACT-2 隱藏陷阱）。
2. **排程 race condition**：兩位主管同時指派同一工作站——應用層檢查會雙雙通過；**資料庫層 unique constraint 才是底**，正好學 transaction。
3. **CSV 編碼**：Excel 存的 CSV 是 CP950 不是 UTF-8——匯入端須偵測或明訂編碼並給清楚錯誤（TECH-10）。
4. **匿名化的位置**：在 template 藏名字＝沒藏（view source 看得到）——必須在 **queryset 層**就不取出真名（PERS-24）。

**Django 專屬坑**：
5. `USE_TZ` 與 naive/aware datetime 混用會炸——開工就決定時區策略，全案一致。
6. Django admin 太好用的反作用：業務規則（TASK-3~7）**不可**只做在 admin 表單——一般 view 也要同一套驗證（抽到 model `clean()` / service 層）。
7. `static/lib/` 資產漏檔（字型 webfonts 最常漏）——版型破了先查 DevTools 404，再查 TECH-12 清單。

## 附錄 C：Demo 劇本（10 分鐘驗收走位；學員自測與老師抽查同一份）

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

| 面向 | V2（本版） | V3 |
|---|---|---|
| 語言/框架 | Python + Django（伺服端渲染） | TypeScript + Bun + Elysia + Refine（SPA） |
| UI | AdminLTE（Bootstrap，template 渲染） | Ant Design（React 元件） |
| 管理介面 | Django admin（**約定即得**） | Refine resources + accessControlProvider（**顯式接**） |
| 資料庫 | SQLite（Django ORM） | PGlite（嵌入式 Postgres，SQL 模板） |
| 驗證 | Django Forms / `clean()` | Elysia `t` + Zod 雙層 |
| 測試 | Django `TestCase` | `bun test` + in-memory PGlite |
| 教學重點 | MVC、ORM、約定優於配置 | 型別安全全棧、REST 契約、顯式權限模型 |

> 兩版功能需求（FACT/TASK/PERS/ACC）編號完全相同——上完 V2 再看 V3，
> 學的是「同一個問題，框架世代如何改變解法」。

---

*v2.1（2026-08-25）：TECH-6/ACC-5 定案 AdminLTE + 2.1.1 UI 版型規範。*
*v2.2（2026-08-25）：TECH-12 離線鐵律/ACC-6 斷網驗收；新增附錄 A~D（里程碑評分/踩坑地圖/Demo 劇本/版本對照）。需求編號不變。*
*v2.3（2026-08-25）：Python 套件管理改採 **uv**（TECH-1/12/13 與 2.1.2 Dockerfile 同步）；功能需求（FACT/TASK/PERS/ACC/EXCL）編號不變。*
