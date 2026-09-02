# Lesson:.gitignore 不支援「行尾註解」——寫了等於沒擋

**踩坑日期**: 2026-09-02
**觸發情境**: 寫 `.gitignore` 時想順手在 pattern 後面加說明
**症狀**: 規則明明寫了，檔案卻照樣被 `git add` 進去;`git check-ignore` 也說沒被忽略

## 根因

`.gitignore` 的 `#` **只有在「一行的開頭」才是註解**。寫在 pattern 後面時，
整行（含空白與註解文字）都被當成 pattern 的一部分：

```gitignore
media/                 # 使用者上傳     ← ✗ pattern 變成 "media/  # 使用者上傳"
```

那個 pattern 不會匹配任何真實路徑，所以 **什麼都沒擋到**，而且**不會有任何錯誤訊息**。
`.dockerignore`、`.npmignore` 同一套規則，同樣的坑。

（對照：`Makefile`、`YAML`、`sh` 都支援行尾註解，所以手會自然這樣寫——這是
「跨工具的肌肉記憶」造成的坑。）

## 解法

註解自己一行，放在 pattern 上方：

```gitignore
# 使用者上傳
media/
```

## 預防

**寫完一定要實測，不能用看的。** 建一個假檔案問 git：

```bash
mkdir -p media && touch media/x.png
git check-ignore -v media/x.png   # 有輸出=有擋到(並顯示是第幾行規則)
                                  # 無輸出=沒擋到
```

掃出檔案裡所有危險寫法：

```bash
grep -nE "^[^#].*[[:space:]]+#" .gitignore    # 有命中=有行尾註解,要改
```

> **更一般的教訓**：「規則寫了」不等於「規則生效」。`.gitignore` 失效是**靜默**的——
> 沒有錯誤訊息，只有幾個月後某次 `git add -A` 把 `.venv/` 或密碼檔送上公開 repo。
> 凡是「靜默失效」的設定，都要有一條指令能驗它。

## 相關

- `FMS_V2/.gitignore`、`FMS_V3/.gitignore`（本次修正處）
- 同源紀律：[mermaid-88-相容基線.md](mermaid-88-相容基線.md) 第 6 條
  「出圖後請 Sponsor 截圖確認渲染——渲染成功不能用假設的」
