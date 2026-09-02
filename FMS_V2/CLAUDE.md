# CLAUDE.md — [PROJECT_NAME]

> **用法**: cp 本模板到新專案後, 直接對 Claude Code 說「**初始化這個專案**」——它會依下方
> 〈初始化引導〉主動發問, 你填一填、勾一勾即可, 不必手動找 `[佔位符]`。
> **來源**: Boris Cherny (Claude Code 創建者) 6 大 workflow + Boris Tane (Cloudflare) Research 實踐, 中文化整合。
> **搭配**: `PLAN_TEMPLATE.md` (Phase/WBS 規劃模板, 需要時複製到 `docs/plan/`)
> **三文件制**: README(給人看動機) / CLAUDE.md(本檔,靜態脈絡) / `CHANGELOG.md`(時間脈絡,
> 變化歷程與決策見它;決策全文在 `docs/99_決策紀錄_ADR.md`)——2026-08-25 OctoAI 立項時核實補齊。
> **閉環機器化**: `scripts/loop_check.sh`(七健檢模板)——收工/過閘前必跑,紅燈不得宣告完成;
> 畫 mermaid 前先讀 `lessons/mermaid-88-相容基線.md`——2026-08-26 OctoAI 實戰回流。

---

## 🚀 初始化引導 (Onboarding Protocol) — **給 Claude Code 讀的劇本**

> **觸發時機**: 本檔第 1 行仍是 `# CLAUDE.md — [PROJECT_NAME]` (佔位符未填) 時, 代表這是**剛 cp 進來的全新專案**。
> 使用者說「初始化 / init / 開始」或問「怎麼開幹」, **你 (Claude Code) 必須先跑完本協議, 才進入任何開發任務**。

**你要做的事 (照順序)**:

### Step 1 — 用 `AskUserQuestion` 分批發問 (不要用純文字問, 要彈選項框)

**第一批 (專案基本盤, 全部必答)**:
1. **專案類型** (單選, 決定要不要 SRS): `探索型/個人工具` · `重構現有系統` · `客戶SoW/政府採購/認證` · `全新產品開發`
2. **技術棧** (單選常見組合 + 「其他」自填): `Python/Django` · `Go/Gin` · `TS/Vue` · `其他(自填)`
3. **主要目的** (自由文字, 走「其他」): 一句話說明做什麼、給誰用

**第二批 (指令, 供 Verify 三綠燈用——問不到就標 TODO 別瞎編)**:
4. **Build / Test / Lint 指令**: 逐一問, 使用者不確定就先填 `[待補]` 並記進 `tasks/todo.md`

> ⚠️ **問答紀律**: 一次最多 4 題; 選項給 2-4 個且互斥; 一定要留「其他」讓使用者自填。
> **需求驅動類型** (客戶/政府/認證) 才追問 SRS 需求編號規則, 其餘類型**跳過 SRS**, 別逼人填。

### Step 2 — 回填佔位符 (機械式, 你直接 Edit)

收到答案後, **全模板取代**這些純文字佔位符 (不是變數, 是要你手動 Edit 的記號):

| 佔位符 | 換成 | 出現處 |
|---|---|---|
| `[PROJECT_NAME]` | 專案名 | 全模板 22 處 / 15 檔 |
| `[SHORT_CODE]` `[PROJECT]` | 專案代號 | SRS / G0 簽認單 |
| `[Language / Framework / DB]` | 技術棧 | 本檔 Project Context |
| `[build command]` 等三指令 | 對應指令或 `[待補]` | 本檔 Project Context |

> **grep 自檢**: 回填後跑 `grep -rn "\[PROJECT_NAME\]" .` 應歸零 (或只剩你刻意留的範例)。

### Step 3 — 依專案類型, 告知「接下來動腦填哪些」(這些**不是**你現在能自動填的)

- **探索型/個人工具** → 填完 Project Context 就能開幹, PLAN_TOGAF / SRS 全跳過
- **重構現有系統** → 先做 Rule 0 Research 讀既有 code, 逐份展開 `docs/01~08` + `PLAN_TOGAF`
- **客戶/政府/認證** → 加填 `docs/SRS.md` 需求編號 + `docs/COMPLIANCE.md` 對照表
- **全新產品** → 從 `PLAN_TOGAF/01_PhaseA` 願景開始, 不需要 `docs/01~08` 現況分析

### Step 4 — 刪掉本〈初始化引導〉整段 + Project Context 的提示框

初始化完成後, 這段劇本對已初始化的專案是雜訊——**連同下方 Project Context 的「(必填,填完刪除)」提示框一起刪掉**, 讓 CLAUDE.md 回歸乾淨的靜態脈絡。

---

## Project Context (必填, 填完刪除此提示框)

```
項目名稱    : [PROJECT_NAME]
技術棧      : [Language / Framework / DB]
主要目的    : [一句話說明]
Build 指令  : [build command]
Test 指令   : [test command]
Lint 指令   : [lint command]
```

---

## Workflow (7 步, 不可跳)

每次接**非瑣碎任務** (3+ 步或涉及架構決策) 都嚴格走完:

| # | 步驟 | 動作 | 產出 |
|---|---|---|---|
| **0** | **Research** | 深入 (deeply) 閱讀相關 code + 檢查 lessons | `tasks/research.md` |
| **1** | **Plan** | 寫可勾選計劃, 標註循環 (用戶批註 → 迭代 1-6 輪), 未確認**不動手** | `tasks/todo.md` |
| **2** | **Subagent** | 複雜研究/並行分析交 Task 子代理, 主 context 保持乾淨 | 整合結論 |
| **3** | **Lessons** | 被糾正 → **立刻**寫進 `tasks/lessons.md`, 同一錯絕不犯第二次 | 教訓庫 |
| **4** | **Verify** | 交付前 build+test+lint 都跑過, 「staff engineer 會 approve 嗎?」 | 3 綠燈 |
| **5** | **Elegance** | 平衡優雅: hacky 就重構, 簡單 bug 別過度設計 | 乾淨 code |
| **6** | **Fix** | 收 bug 直接修: 復現 → 根因 → 最小 fix → 回歸測 → 根因說明。方向錯 revert 別打補丁 | 修好 + 根因 |

**任務結束更新 `tasks/todo.md` 的 Review 小節**: 實際做了什麼、與計劃偏差、下次改進。

---

## Commit 節奏 (**3 步一組, 不可拆**)

**myflaskapp 實戰教訓** — 一路 commit 卻沒回頭打勾 todo 的鐵律:

```
1. 驗證綠 (build+test+lint 三綠燈)
   ↓
2. 打勾 tasks/todo.md 對應項目 (含子區塊)
   ↓
3. git commit
```

**這 3 步是原子動作**, 分開做就會漏。**若 test 沒綠, 別 commit**; **若 todo 沒打勾, 別 commit**。

---

## 閉環 LOOP (目標→驗收→回饋, 三圈都要轉; 2026-08-26 OctoAI 實戰回流)

| 圈 | 轉法 | 斷圈=紅燈 |
|---|---|---|
| **需求圈** | 目標/KPI (綁需求編號) → 工項驗收 → **COMPLIANCE Evidence 回寫** (需求從 ⬜ 變 ✅) | **不回寫=工項不算完** |
| **執行圈** | todo 打勾 → commit (核實紀錄) → CHANGELOG 條目 (里程碑級) → todo Review (偏差+改進) | commit 了沒打勾/沒條目 |
| **學習圈** | 被糾正 → tasks/lessons 立刻記 → session 末歸 lessons/ → 下輪開工先 review | 同錯犯第二次 |

**機器守門**: `scripts/loop_check.sh` 自動檢查三圈是否漂移——寫在文件裡的 loop 誰都會漂,
**能讓紅燈擋住你的才是真閉環**。收工/過閘前必跑, 紅燈不得宣告完成。

---

## Core Principles (4 底線)

| 原則 | 具體體現 |
|---|---|
| **Simplicity First** | 只碰必要 code, 不順便重構周邊 |
| **No Laziness** | 找根因, 拒 workaround。方向錯 revert 不打補丁 |
| **Minimal Impact** | 檔案 ≤ 300 行, 不動穩定模組 |
| **No Island Code** | 新 code 必融入現有系統 (快取、API 慣例、遷移工具、權限模型、測試 helper) |

---

## Rule 0: Research 深度閱讀 (最關鍵)

**用詞決定研究深度** — 必須用: 「深入地 (deeply)」「極其詳細地 (in great details)」「複雜之處 (intricacies)」

範例指令 (直接複製用):

```
深入地 (deeply) 閱讀 [資料夾/模組], 理解其運作方式與複雜之處 (intricacies)。
完成後, 將你的學習與發現寫成一份詳細的報告並存入 tasks/research.md。
```

**產出物必須寫檔案** — `tasks/research.md`, 不能只在聊天窗總結 (無法審查、無法追溯)。

**Island Code 檢查** — Research 階段主動確認:

| 高風險點 | 要確認的問題 |
|---|---|
| 快取層 | 現有快取策略是什麼? 新 code 會繞過或破壞它嗎? |
| DB 遷移慣例 | 現有 migration 工具和命名規則是什麼? |
| API 結構 | 現有 API 的命名、版本、錯誤格式慣例是什麼? |
| 權限模型 | 現有的授權邏輯在哪裡? 新功能需要接入嗎? |
| 測試 helper | 現有的測試工廠和 mock 策略是什麼? |

---

## Rule 1: Plan 標註循環

1. Claude 輸出初稿計劃到 `tasks/todo.md`
2. 你在編輯器直接批註 (例: 「不用 cache」「用現有 Queue」)
3. 告訴 Claude: 「我加了筆記, 請根據筆記更新計劃, 先不要實作。」
4. 重複 1-6 輪, 直到計劃完美再執行

**規劃未獲確認前, 絕不開始寫 code。**

---

## Rule 3: Self-Improvement Loop

每次被糾正 → **立刻**寫進 `tasks/lessons.md`, 格式:

```
❌ 錯誤: [描述] → ✅ 正確: [解法]
```

按類別整理 (API 設計 / 快取 / 測試 / ...)。**Session 開始先 review lessons.md**。

---

## Rule 6: 修 Bug SOP

1. **穩定復現** — 確定輸入 → 確定輸出
2. **定位根因**, 不是症狀
3. **最小 fix**, 不順便重構
4. **回歸測** — 確認不破現有測試
5. **寫 lessons** 記錄根因 (超過 30 分鐘的 bug 必寫)
6. **方向錯 revert 別打補丁**

---

## Code Conventions

### ✅ Always

- 錯誤 wrap: `fmt.Errorf("context: %w", err)` 或等效, 保留 error chain
- 依賴注入: constructor 傳入, 不用 global
- Context 傳遞: DB / HTTP / Cache 呼叫都要吃 context
- 業務層必寫單元測試, table-driven

### 需求驅動專案的加碼規則 (**若專案有 `docs/SRS.md`**)

若專案是需求驅動 (學校作業 / 客戶 SoW / 政府採購 / 認證), **這 4 條是硬紅線**:

| 規則 | 具體體現 |
|---|---|
| **需求編號絕不改** | SRS 定的 TECH-1 / FACT-7 / TASK-10 / PERS-9 一經定, 只能新增或 deprecate, 不能改編號 |
| **測試命名引用需求編號** | 測試 class / method 註解必須寫「Covers: TECH-N, FACT-M」— 未來反查零成本 |
| **業務規則集中一個 module** | BR-01~08 全放同一個 validator (參 FMS `scheduling/services.py → SchedulingValidator`), 別散在各 view — Ousterhout deep module 教科書實例 |
| **改 code 立刻同步 COMPLIANCE.md** | 動了哪個需求對應的 code, 立刻更新 `docs/COMPLIANCE.md` 對應段 Evidence — 別留到 v2.0 才補, 到時已忘 |

**測試命名範例** (FMS 標本, 直接抄):

```python
class TimeConstraintTests(TestCase):
    """Covers: BR-01 (weekday only), BR-02 (≤6hr), BR-03 (same day), FACT-7 (06:00-18:00)"""

    def test_task_must_be_weekday(self):
        """BR-01: 週末不能排"""
        ...
```

**若你的專案沒有 SRS.md, 這 4 條可忽略。**

### ❌ Never

- ❌ Handler 塞業務邏輯 → 拆 service 層
- ❌ Global 變數存 config / state
- ❌ 忽略 error (顯式處理或 log)
- ❌ 檔案超過 300 行 (拆)
- ❌ 相同邏輯複製 > 3 次 (提 function)

### Security 紅線

- ❌ 內部錯誤 stack trace 直接返 HTTP response
- ❌ 明文存密碼 / API key
- ❌ 跳過輸入驗證 (「先跑起來再說」)
- ❌ **環境變數用通用名** (`DATABASE_URL` / `SECRET_KEY` / `REDIS_URL`) — 會被系統既有變數污染 (myflaskapp 教訓: 本機 `DATABASE_URL` 已指向另一個 Postgres, 覆蓋預設導致 import psycopg2 崩)
- ✅ **環境變數用專案 prefix** (`FMS_DATABASE_URL` / `MYAPP_SECRET_KEY`) — 避免撞系統既有變數 (No Island Code: 別假設全域環境乾淨)
- ✅ 登入失敗**不揭露具體原因** (統一「認證失敗」)

---

## Task Management (7 步閉環)

**standard tier** 專案有**兩層 lessons**:

```
tasks/                    # 短期 (單一任務/session)
├── research.md           # rule 0 產出 (每次任務前必寫)
├── todo.md               # rule 1 產出 (可勾選, 實時更新)
└── lessons.md            # rule 3 臨時教訓, session 結束整理進 lessons/

lessons/                  # 長期 (跨 session/team 共享)
├── README.md             # index (哪個 lesson 講什麼)
└── [category]_xxx.md     # 個別 lessons

docs/
├── plan/
│   └── README.md         # Phase 進度總覽 (長期規劃)
└── ref/
    └── README.md         # 外部文獻探索 (避免重複研究)
```

**tasks/ vs lessons/ 分工**:

| 目錄 | 生命週期 | 內容 |
|---|---|---|
| `tasks/` | 短期 (單一任務/session) | 進行中的研究、當前 todo、臨時 lesson |
| `lessons/` | 長期 (永久保留) | 已提煉、可重複參考的踩坑筆記 |

**Session 結束前**: tasks/lessons.md 有東西 → 整理成 `lessons/xxx.md` 一篇 + update `lessons/README.md` index。

**初始化** (首次或清理後):
```bash
mkdir -p tasks && touch tasks/{research,todo,lessons}.md
```

**todo.md 範本**:
```markdown
## Task: [任務名稱]
**目標**: [一句話]
**日期**: YYYY-MM-DD

### Plan
- [ ] Step 1
- [ ] Step 2

### Review
(完成後填: 實際做了什麼、與計劃偏差、下次改進)
```

**lessons.md 範本**:
```markdown
# Lessons — [PROJECT_NAME]

## API 設計
- ❌ 錯誤: xxx → ✅ 正確: xxx

## 快取
- ❌ 錯誤: xxx → ✅ 正確: xxx
```

---

## Common Tasks

### 新增 Feature
1. **Research** — 深入讀相關 module + 檢查 lessons, 寫 `tasks/research.md`
2. **Plan** — `tasks/todo.md` 可勾選, 標註循環確認到完美
3. **Implement** — 逐項執行, 每步說明理由
4. **Verify** — Build → Test → Lint → Diff
5. **Doc** — 更新相關文件

### 修 Bug
1. 先查 `tasks/lessons.md` — 之前踩過嗎?
2. 穩定復現
3. 定位根因
4. 最小 fix
5. 更新 lessons
6. 方向錯直接 revert

### Code Review Checklist
- [ ] 改動範圍最小化? (符合 tasks/todo.md 計劃)
- [ ] 有對應測試?
- [ ] 錯誤都有處理?
- [ ] 有安全隱患? (輸入驗證、錯誤暴露)
- [ ] 檔案 ≤ 300 行?
- [ ] 有重複 code 可提?
- [ ] 是否破壞現有快取、API 慣例、遷移工具?

---

## TL;DR

**7 步 workflow**: Research → Plan → Subagent → Lessons → Verify → Elegance → Fix

**4 底線**: Simplicity / No Laziness / Minimal Impact / No Island Code

**3 個必備檔案**: `tasks/research.md` + `tasks/todo.md` + `tasks/lessons.md`

**初始化**: `mkdir -p tasks && touch tasks/{research,todo,lessons}.md`

**搭配**: [pm-skills playbook](../pm-skills/docs/playbook.md) 5 情境動作腳本

---

**版本**: v3.1 (整合 Boris Cherny 6 workflow + Boris Tane Research + 4 底線)
**來源**: [watchdog CLAUDE.md](/d/mygo20/watchdog_agent/watchdog_remote/docs/plan/claude_code/CLAUDE.md) + [gclaw CLAUDE.md](/d/myagent/gclaw/CLAUDE.md) 融合
