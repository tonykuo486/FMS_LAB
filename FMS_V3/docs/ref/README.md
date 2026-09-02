# Reference — [PROJECT_NAME]

> **這是什麼?** 外部文獻探索目錄, 避免重複研究。
> **什麼該寫這裡?** 不是文件複製, 是**你對這份外部資料的判斷 + 對本專案的意義**。
> **參考**: [gclaw docs/ref/](/d/myagent/gclaw/docs/ref/) 的做法

---

## 文件索引

| 文件 | 說明 | 相關 Phase |
|---|---|---|
| [ai_agent.md](ai_agent.md) | [外部工具/框架比較] | Phase [N] |
| [xxx.md](xxx.md) | [說明] | — |

---

## 寫 ref 的原則

1. **不複製原文** — 貼 URL + 你的判斷。原文會過期, 判斷才是資產
2. **明確標「什麼時候該引用」** — 未來寫 PR / code review 時可以指這篇當論據
3. **明確標「什麼時候別引用」** — 邊界 case 也寫, 避免過度套用
4. **對照本專案的實例** — 這份外部方法論在**你的 code** 裡有沒有標本?

**好範例**: [gclaw codebase_design_ousterhout.md](/d/myagent/gclaw/docs/ref/codebase_design_ousterhout.md) — Ousterhout deep module 對照 gclaw 4 底線 + 標本 (masking / memos)。

---

## 相關

- [../plan/README.md](../plan/README.md) — Phase 規劃
- [../../CLAUDE.md](../../CLAUDE.md) — 工程規範
