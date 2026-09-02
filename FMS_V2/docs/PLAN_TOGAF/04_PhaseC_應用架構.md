# Phase C · 應用架構 (Application Architecture)

> **TOGAF Phase C**: Information Systems Architectures — Application Architecture。
> 對應 TOGAF 四大架構領域中的「應用架構」層：部署的應用程式及其互動藍圖。
> 資料架構見 [03_PhaseC 資料架構](03_PhaseC_資料架構.md)。
> 細節引用 [../06 目標架構](../06_目標架構設計.md) / [../08 開工設計](../08_開工設計.md)。
> **撰寫日期**: YYYY-MM-DD

---

## 1. 應用元件切分

```
[畫元件圖: 上游 / 新元件 / 既有元件保留 / 下游]
```

## 2. 元件職責

| 元件 | 職責 | 技術實作 | 部署位置 |
|---|---|---|---|
| [comp 1] | | | |
| [comp 2] | | | |

## 3. 介面契約 (Interfaces)

**上游 → 本系統**:
- 介面: [event / API / DB polling]
- Schema: [連結或摘要]
- SLA: [吞吐 / latency]

**本系統 → 下游**:
- 介面: [event / API / file]
- Schema: [連結或摘要]
- SLA: [吞吐 / latency]

**內部元件間**:
- Queue 訊息格式: [連結 08]

---

## 4. 與既有系統的整合點

| 整合點 | 現況 | To-Be | 誰負責 |
|---|---|---|---|
| | | | |

---

## 5. 相關文件

- [03_PhaseC 資料架構](03_PhaseC_資料架構.md)
- [../06 目標架構](../06_目標架構設計.md)
- [../08 開工設計](../08_開工設計.md)
