# Lessons — [PROJECT_NAME]

> **這是什麼?** 長期踩坑筆記 (跨 session / team-shared, 換電腦帶著跑)。
> **與 `tasks/lessons.md` 差別**: tasks 是臨時, 這裡是永久提煉。
> **參考**: [gclaw lessons/](/d/myagent/gclaw/lessons/) 的做法

---

## Lesson 索引 (按類別)

### API 設計 / 資料模型

- [xxx_naming.md](xxx_naming.md) — [一句話說明]

### 效能 / 快取

- [xxx.md](xxx.md) — [一句話說明]

### 除錯 / 監控

- [xxx.md](xxx.md) — [一句話說明]

### 部署 / 環境

- [xxx.md](xxx.md) — [一句話說明]

### 框架 / 工具的坑

- [xxx.md](xxx.md) — [一句話說明]

---

## 寫 lesson 的觸發條件

- **超過 30 分鐘除錯的 bug** → 一定寫
- **同一坑踩第二次** → 一定寫 (第一次沒寫, 第二次要補記且反省為什麼沒寫)
- **被 user / reviewer 糾正過的方向** → 一定寫
- **踩到框架 / 工具的非直覺行為** → 一定寫 (別人也會踩)

---

## Lesson 檔案結構範本

每個 `xxx.md` 包含:

```markdown
# [問題一句話]

**踩坑日期**: YYYY-MM-DD
**觸發情境**: [什麼時候會遇到]
**症狀**: [看起來像什麼]

## 根因

[真正的原因, 不是表面症狀]

## 解法

[做了什麼修好]

## 預防

[未來怎麼避免]

## 相關

- [涉及的 code 檔案 / commit]
```
