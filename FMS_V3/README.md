# [PROJECT_NAME]

> 一句話說明: [做什麼, 給誰用, 解決什麼問題]

---

## 30 秒版

[產品 / 工具 / script 做什麼, 用 3-5 行講清楚。像 SPD_2607 的 00_README 那樣。]

---

## 技術棧

- **語言**: [Python / Go / TS / ...]
- **框架**: [Django / Gin / Vue / ...]
- **DB**: [SQLite / PostgreSQL / ...]
- **部署**: [Docker / systemd / 本機 exe / ...]

---

## Quick Start

```bash
# 安裝依賴
[install command]

# Build
[build command]

# Run
[run command]

# Test
[test command]
```

---

## 專案結構

```
[project]/
├── CLAUDE.md               # AI 開發規則 (7 workflow + 4 底線)
├── README.md               # 本檔
├── PLAN_TEMPLATE.md        # Phase/WBS 模板 (複製到 docs/plan/)
├── tasks/                  # 短期任務 (單一 session)
│   ├── research.md         # rule 0 產出
│   ├── todo.md             # rule 1 產出
│   └── lessons.md          # rule 3 臨時教訓
├── lessons/                # 長期踩坑筆記 (team-shared)
│   └── README.md           # index
├── docs/
│   ├── plan/
│   │   └── README.md       # Phase 進度總覽
│   └── ref/
│       └── README.md       # 外部文獻探索
└── [src/]                  # 源碼
```

---

## 當前 Phase

| Phase | 名稱 | 狀態 | 完成日期 | 關鍵交付物 |
|-------|------|------|---------|-----------|
| 0 | 基礎設施 | 📝 進行中 | — | [核心交付物] |
| 1 | 核心功能 | 📋 規劃中 | — | [核心交付物] |
| 2 | 驗證與安全 | 📋 規劃中 | — | [核心交付物] |

> 詳細計劃見 [docs/plan/README.md](docs/plan/README.md)

---

## 第一個任務 (給 Claude Code)

```
深入地 (deeply) 閱讀專案結構, 理解其複雜之處 (intricacies)。
將發現寫入 tasks/research.md。
然後幫我規劃第一個 Phase 的 WBS 並寫入 tasks/todo.md, 確認後開始實施。
```

---

## 相關

- [CLAUDE.md](CLAUDE.md) — AI 工程規範
- [PLAN_TEMPLATE.md](PLAN_TEMPLATE.md) — Phase/WBS 模板
- [pm-skills playbook](../pm-skills/docs/playbook.md) — 5 情境動作腳本
