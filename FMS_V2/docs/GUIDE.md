# 課程指引（Course Guide）：FMS_V2

**Factory Management System — Python / Django 版** ｜ v1.0（2026-08-25）

> **這份文件回答「怎麼學」。** 需求（做什麼）見 [`SRS.md`](SRS.md)；
> 設計（怎麼做）見 [`SDD.md`](SDD.md)。

| | 全名 | 內容 |
|---|---|---|
| [SRS.md](SRS.md) | Software Requirements Specification | 需求（做什麼）——逐條驗收 |
| [SDD.md](SDD.md) | Software Design Document | 設計（怎麼做）——UI 版型與部署 |
| **GUIDE.md**（本檔） | Course Guide | 教學（怎麼學）——里程碑、踩坑地圖 |

## 怎麼用這三份文件

```
開工前 ── 讀 SRS 第 2 章(每條編號都是驗收項)
            ↓
         讀 GUIDE §2 踩坑地圖(★先讀,能省好幾小時)
            ↓
         讀 SDD §1 UI 版型 / §2 部署規格
            ↓
實作中 ── 照 GUIDE §1 里程碑 M1~M6 推進
            ↓  遇到技術問題 → 查 SDD 對應章節
            ↓
驗收前 ── 照 SRS 附錄 Demo 劇本自測一遍(老師抽查同一份)
```

---

## 1. 里程碑與評分

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

## 2. 踩坑地圖（開工前先讀，撞到再回來對號入座）

**共通坑（不分技術棧）**：
1. **ISO 8601 週次**：一年可能有 53 週；1/1 可能屬於「去年第 52 週」——用 `date.isocalendar()`，自己算必錯（FACT-2 隱藏陷阱）。
2. **排程 race condition**：兩位主管同時指派同一工作站——應用層檢查會雙雙通過；**資料庫層 unique constraint 才是底**，正好學 transaction。
3. **CSV 編碼**：Excel 存的 CSV 是 CP950 不是 UTF-8——匯入端須偵測或明訂編碼並給清楚錯誤（TECH-10）。
4. **匿名化的位置**：在 template 藏名字＝沒藏（view source 看得到）——必須在 **queryset 層**就不取出真名（PERS-24）。

**Django 專屬坑**：
5. `USE_TZ` 與 naive/aware datetime 混用會炸——開工就決定時區策略，全案一致。
6. Django admin 太好用的反作用：業務規則（TASK-3~7）**不可**只做在 admin 表單——一般 view 也要同一套驗證（抽到 model `clean()` / service 層）。
7. `static/lib/` 資產漏檔（字型 webfonts 最常漏）——版型破了先查 DevTools 404，再查 TECH-12 清單。

## 3. V2 / V3 對照（同一份需求，兩個世代的實作）

| 面向 | V2（本版） | V3 |
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

*v2.1（2026-08-25）：TECH-6/ACC-5 定案 AdminLTE + [SDD §1](SDD.md) UI 版型規範。*
*v2.2（2026-08-25）：TECH-12 離線鐵律/ACC-6 斷網驗收；新增附錄 A~D（里程碑評分/踩坑地圖/Demo 劇本/版本對照）。需求編號不變。*
*v2.3（2026-08-25）：Python 套件管理改採 **uv**（TECH-1/12/13 與 [SDD §2](SDD.md) Dockerfile 同步）；功能需求（FACT/TASK/PERS/ACC/EXCL）編號不變。*
