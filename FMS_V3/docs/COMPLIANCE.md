# SRS Compliance Report — [PROJECT_NAME]

> **這是什麼?** 需求 ↔ 實作 ↔ 測試 的**逐條對照表**。改動 code 後**立刻更新**對應 Evidence 段。
> **搭配**: [SRS.md](SRS.md) — 需求規格書 (只列需求, 不列實作證據)
> **啟發**: [FMS SRS_Compliance_Report v2.0](/d/myESRS/Factory_Management_System/docs/SRS_Compliance_Report.md) — 100% 符合率 (58/58), 93 tests
> **可跳過**: 沒 SRS.md 的專案不用寫

---

## 版本

| 版本 | 日期 | 符合率 | 測試數 | 主要變更 |
|---|---|---|---|---|
| v1.0 | YYYY-MM-DD | X% (N/M) | K tests | 初版 |
| v2.0 | YYYY-MM-DD | 100% (M/M) | K tests | 修復 DEF-01 / DEF-02 |

---

## Executive Summary

**專案**: [PROJECT_NAME]
**實作技術**: [語言 / 框架 / DB]
**Test 命令**: `[e.g. python manage.py test --verbosity=1]`
**Test 結果**: **K tests, 0 failures, 0 errors**

| Category | Requirements | Implemented ✅ | Partial ⚠️ | Missing ❌ |
|---|---:|---:|---:|---:|
| TECH (技術規格) | 11 | 11 | 0 | 0 |
| FACT (實體結構) | 7 | 7 | 0 | 0 |
| TASK (業務任務) | 10 | 10 | 0 | 0 |
| PERS (角色權限) | 25 | 25 | 0 | 0 |
| ACC (驗收標準) | 5 | 5 | 0 | 0 |
| **Total** | **58** | **58** | **0** | **0** |

**Overall Compliance: 100% (58/58)**

> Previous version 1.0 reported N defects (DEF-01, DEF-02, ...).
> Both have been resolved and verified by test suite in version [current].

---

## Part 1 — TECH: 技術規格

### TECH-1 ✅ — [需求標題]

**Requirement**: [從 SRS.md 抄過來一句話]

**Evidence**:
- [程式碼位置 1, 例: `requirements.txt` specifies Python 3.11 via ...]
- [程式碼位置 2]
- [文件位置 3, 例: `README.md`: ...]

**Test**: [測試檔案::測試類別, 例: `accounts/tests.py::CustomUserModelTest`]

---

### TECH-2 ✅ — [需求標題]

**Requirement**:

**Evidence**:
- `[file:line]` — [說明]

**Test**:

---

## Part 2 — FACT: 實體結構

### FACT-1 ✅ — [需求標題]

**Requirement**:

**Evidence**:

**Test**:

---

## Part 3 — TASK: 業務任務

### TASK-1 ✅ — [需求標題]

**Requirement**:

**Evidence**:
- Business logic: `[file:line]` — [如何實作]
- 若有規則集中位置: `services.py → [ValidatorClass].[method]()`

**Test**: `[test_file]::[TestClass]::[test_method]`

---

## Part 4 — PERS: 角色權限

### PERS-1 ✅ — [需求標題]

**Requirement**:

**Evidence**:
- Auth check: `[decorator / middleware / permission class]`
- View: `[view_file:line]`
- Template: `[template_file]` (若有 UI)

**Test**:

---

## Part 5 — ACC: 驗收標準

### ACC-1 ✅ — [端到端場景名稱]

**Scenario**: [Given / When / Then]

**Evidence** (實作證明):
- User journey: `[URL 1] → [URL 2] → [URL 3]`
- Integration test: `[test_file]::[TestClass]`

**Test result**: ✅ Passed / ⚠️ Partial / ❌ Failed

**Sign-off**: [誰簽收 / 日期 / 或 pending]

---

## 測試對照表 (**核心, 每次跑測試後更新**)

**Test 命令**: `[e.g. python manage.py test --verbosity=1]`

**測試分組對照 SRS 章節** (參 FMS 標本):

| Test Group | Test Class | Tests | Covers | Location |
|---|---|---:|---|---|
| [module_1] | [TestClass_A] | N | TECH-N/M/O | `[path]` |
| [module_1] | [TestClass_B] | N | FACT-N | `[path]` |
| [module_2] | [TestClass_C] | N | TASK-N, BR-N | `[path]` |
| [module_2] | [TestClass_D] | N | PERS-N | `[path]` |
| [integration] | [E2ETestClass] | N | ACC-N, IT-N | `[path]` |
| **Total** | | **K** | | |

---

## Defect Tracking (缺陷追蹤 v1 → v2)

**每個 v1 → v2 之間修復的 defect 都在這裡留痕, 並在 [../99_決策紀錄_ADR.md](../99_決策紀錄_ADR.md) (enterprise tier) 或 [plan/README.md 的 ADR 表](plan/README.md#重大決策-輕量-adr) (standard tier) 開對應 ADR**:

### DEF-01 [需求編號]: [缺陷標題]

**發現日期**: YYYY-MM-DD
**發現方式**: [手動測試 / UAT / CI 掛掉]

**症狀**:
[描述問題]

**根因**:
[真正的原因]

**Fix**:
- Code: `[file:line]` — [做了什麼]
- Test: `[test_file]::[test_method]` — [加了什麼測試防回歸]

**Verification**:
- Before: [失敗證據]
- After: [通過證據]

**Related ADR**: [ADR-N] (若有)

---

### DEF-02 [需求編號]: [缺陷標題]
...

---

## Overall Score

**Compliance rate**: 100% (58/58)
**Test pass rate**: 100% (K/K, 0 failures, 0 errors)
**Defect count** (open): 0
**Defect count** (fixed in this version): [N]

---

## 相關

- [SRS.md](SRS.md) — 需求規格書 (只列需求)
- [../CLAUDE.md](../CLAUDE.md) — 開發規則 (測試命名必須引用需求編號)
- [plan/README.md](plan/README.md) — Phase 進度 + 輕量 ADR

---

## 使用建議 (寫完後刪除)

1. **每次 commit 前**: 若這 commit 涉及某個 SRS 需求, **更新該需求的 Evidence 段** (加新 file:line, 或標 ✅ / ⚠️)
2. **每次跑測試後**: 若測試數變動, 更新測試對照表
3. **每次修 defect**: 開新 DEF-N 條目, 別複寫已 close 的
4. **v2.0 版本升級的觸發時機**: 累積 5+ defect 修復, 或 major refactor 後
5. **給 sponsor 看的**: Executive Summary + Part 5 (ACC) + Overall Score, 其他章節是給接手者看的
