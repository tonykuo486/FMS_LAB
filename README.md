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
├── docs/
│   └── V2_V3_對照表.md       ← 兩版完整對照（講師備課/學員課後對讀）
├── FMS_V2/
│   └── docs/SRS.md           ← V2 需求規格 v2.2：Python + Django + SQLite + AdminLTE
└── FMS_V3/                   ← 獨立 git repo（可推 GitHub 發給學員）
    └── docs/SRS.md           ← V3 需求規格 v3.2：Bun + Elysia + PGlite + Refine + AntD
```

## 兩個版本一眼看

| | **V2** | **V3** |
|---|---|---|
| 路線 | 約定優於配置（伺服端渲染） | 顯式契約（型別安全全棧） |
| 棧 | Python 3 / Django / SQLite / AdminLTE | TypeScript / Bun / Elysia / PGlite / Refine + Ant Design |
| 適合 | 第一個 Web 專案的初學者 | 已懂 HTTP/SQL，要學前後端分離 |
| 規格 | [FMS_V2/docs/SRS.md](FMS_V2/docs/SRS.md) | [FMS_V3/docs/SRS.md](FMS_V3/docs/SRS.md) |

功能需求兩版**一字不差**（編號相同）；差異全在實作層——詳見
[docs/V2_V3_對照表.md](docs/V2_V3_對照表.md)。

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
4. 進度照 SRS **附錄 A 里程碑（M1~M6）**；驗收照 **附錄 C Demo 劇本**（兩版同一份，10 分鐘走位）。

**學員**：
1. 精讀你那版的 `docs/SRS.md` 第 2 章——**每一條編號都是驗收項**。
2. 開工前先讀 **附錄 B 踩坑地圖**（ISO 第 53 週、排程 race、CSV 編碼是必撞的三個）。
3. 依 M1~M6 交付，commit 歷史要看得出里程碑節奏（最後一天一包 zip 直接扣分）。
4. 自測用附錄 C 劇本走一遍——老師抽查用的是同一份。

## 三條不變的鐵律（兩版通用，驗收必查）

1. **後端守衛才是安全**——前端/模板擋掉按鈕不算數，每個端點都要有自己的權限檢查。
2. **資料庫約束才是底**——排程衝突的應用層檢查有 race，unique/exclude 約束保底。
3. **完全離線**——斷網展示全部功能，DevTools Network 零外部請求（ACC-6）。
4. **交付即 Compose**——開發期隨你 dev server，驗收一律 `docker compose up -d` 三步啟動
   （ACC-7），且 `down`/`up` 後資料仍在（volume 驗證）。

---

*文件維護約定：需求或技術棧變動時，同步三處——兩版 `SRS.md` ＋ `docs/V2_V3_對照表.md`。*
