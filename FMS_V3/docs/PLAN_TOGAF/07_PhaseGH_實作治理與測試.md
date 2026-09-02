# Phase G+H · 實作治理、變更管理與測試資料交付

> **TOGAF Phase G** (Implementation Governance) + **H** (Change Management) + Requirements Management。
> **撰寫日期**: YYYY-MM-DD

---

## 0. 閉環 LOOP 總綱 (目標→驗收→回饋, 三圈都要轉; 2026-08-26 增補)

治理的靈魂不是開會, 是**三個回饋圈都在轉**——任何一圈斷掉, 下面的查核清單都只是儀式:

1. **需求圈**: KPI (綁需求編號) → WBS 工項驗收 → [COMPLIANCE Evidence](../COMPLIANCE.md) 回寫——**不回寫=工項不算完**。需求編號體系見 [../SRS.md](../SRS.md) (TECH/FACT/TASK/PERS/ACC/BR/...)。
2. **執行圈**: todo 打勾 → commit (核實紀錄) → CHANGELOG → Review 小節 (偏差+改進)。
3. **學習圈**: 被糾正即記 lessons → 歸檔 → 下輪開工先 review——同錯不犯二次。

**機器守門**: `scripts/loop_check.sh` (七健檢) 為每個 Gate 的必附憑據; 紅燈不得宣告過閘。
G0 簽認必錨版本基線 (見 07 模板一之二節)。

## 1. 治理節奏

| 會議 / 機制 | 頻率 | 參與 | 內容 |
|---|---|---|---|
| 週進度查核 | 每週 | SPO/SA/DBA/QA | WBS 燃盡、查核點證據抽查、風險 |
| Gate 審查 | G0-G4 各一次 | 依 [06 §0](06_PhaseEF_遷移計畫_WBS.md#0-里程碑與閘門-gate-總覽) 判定者 | 憑證據判定, 留紀錄入 repo |
| 對帳差異即時查 | 差異 > 0 當日 | QA 召集 SA/DEV | §4 SOP |
| ADR 審查 | 需要時 | SPO + 相關角色 | §6 |

---

## 2. Done 定義 (DoD) — 每個 WBS 任務通用

一個任務算完成, 必須**同時**:

1. **產出入版控** (程式 / DDL / 報告 / 紀錄, repo 內有連結可追)
2. **查核點證據留檔** (測試輸出、實測數據、簽認紀錄 — 不是口頭「做完了」)
3. **測試資料交付登錄**: 該任務對應的 TD-x (§5) 已存放於指定位置並可重跑
4. **簽核者 ≠ 實作者** (QA 或對應 A 角色打勾)

---

## 3. PR / 程式合規查核清單 (每次合併前, SA 自查 + 審查者複查)

- [ ] 未觸碰契約 schema / 寫入語意 (契約 C-1)
- [ ] 對 [受保護的表] 的 UPDATE 僅限白名單欄 (C-3); 無動態 SQL
- [ ] 無硬編碼帳密 / IP (grep 規則入 CI)
- [ ] 失敗路徑必有: 非 0 退出碼 / DLQ / 告警之一; 禁止吞錯 (trigger 除外, ADR-N 特許)
- [ ] 冪等: 新寫入邏輯附「重複執行」測試
- [ ] DDL 變更: 逐條對六鐵律打勾 + DBA 審
- [ ] 新增外部相依 (套件 / 服務) 有紀錄

---

## 4. 例外處理 SOP

### 4.1 每日對帳差異 > 0 (QA 主導)

1. **分類**:
   - **缺列** (shadow / 正式少) = 漏算候選
   - **多列** = 孤兒候選
   - **欄值差** = 邏輯不一致
2. **缺列** → 查 ingest log: 該事件有無? 無 = 擷取漏 (查 trigger/outbox); 有 = 反查漏 (WP5 迴圈)
3. **孤兒** → 確認為 key 欄值變動殘留 → 登錄孤兒清單 → 清理動作**僅允許刪除** [條件], 由 QA 簽核後執行, 腳本入版控
4. **欄值差** → 對照 07 核實邏輯, 若原邏輯錯 → 修 shadow; 若新邏輯錯 → 修 To-Be code

### 4.2 生產告警觸發

1. On-call 收告警 → [X 分鐘] 內確認
2. 分類: [P0 / P1 / P2]
3. P0: 立即回滾 (走 rollback SOP)
4. P1/P2: 值班群組討論, 決定 hot fix vs 排 backlog

---

## 5. 測試資料交付清單 (TD-x)

**每個 WBS 任務對應的測試資料, 命名 + 存放位置**:

| TD-# | 內容 | 產出時機 | 存放位置 | 負責人 |
|---|---|---|---|---|
| TD-1 | 黃金樣本 fixture | WP1-T1 | `tests/fixtures/golden/` | QA |
| TD-2 | 現況效能基準 | WP1-T2 | `docs/baseline/perf.md` | SA/DBA |
| TD-3 | 現況錯誤基準 | WP1-T3 | `docs/baseline/errors.md` | QA |
| TD-4 | 核心邏輯 unit test | WP4-T2 | `tests/unit/` | SA |
| TD-5 | 反查測試 | WP4-T5 | `tests/lookup/` | SA |
| TD-6 | 冪等測試 | WP4-T6 | `tests/idempotent/` | SA |
| TD-7 | E2E 整測 | WP4-T8 | `tests/e2e/` | QA |
| TD-8 | DDL 效能實測 | WP2-T2 | `docs/perf/ddl.md` | DBA |
| TD-9 | 召回率重放 | WP5-T1 | `docs/recall/report.md` | QA |

---

## 6. ADR 變更流程

**新增 ADR**:
1. 有人 (通常 SA) 撰寫 ADR 草稿 (參 [../99 格式](../99_決策紀錄_ADR.md))
2. Sponsor + 相關角色審查
3. 通過 → 入 [../99](../99_決策紀錄_ADR.md), status = 已定案
4. 拒絕 → status = 已拒絕, 保留紀錄 (未來再問時可查)

**推翻既有 ADR**:
1. 撰寫**新 ADR** 說明推翻理由 (不改舊 ADR)
2. 舊 ADR status → 已推翻 (改由 ADR-N)
3. 影響 code 走一般 PR 流程

---

## 7. Requirements Register (R1-R∞)

**追蹤所有需求 + 狀態**:

> **若專案有 [../SRS.md](../SRS.md)** (需求驅動: 客戶 SoW / 政府採購 / 認證): 「來源」欄直接引用 SRS 編號 (`TECH-N` / `FACT-N` / `TASK-N` / `PERS-N` / `ACC-N` / `BR-N`),
> 狀態變 ✅ 的憑據是 [../COMPLIANCE.md](../COMPLIANCE.md) 對應段的 Evidence 已回寫 (呼應 §0 需求圈)。**沒有 SRS 的探索型專案**: 來源填 Phase A/B 章節即可。

| R# | 需求 | 來源 (SRS 編號 或 Phase 章節) | 狀態 | 對應 WBS |
|---|---|---|---|---|
| R1 | [商業驅動 1] | [01 §1] 或 `ACC-1` | ✅ 已納入 | WP4 |
| R2 | [業務不可破壞 1] | [02 §3] 或 `BR-04` | ⏳ 驗證中 | WP6 |
| R3 | | | | |

---

## 8. 相關

- [06_PhaseEF WBS](06_PhaseEF_遷移計畫_WBS.md) — WBS 本體
- [08_G0_Kickoff](08_G0_Kickoff簽認單.md) — G0 判定
- [../99 ADR](../99_決策紀錄_ADR.md) — 決策留痕
