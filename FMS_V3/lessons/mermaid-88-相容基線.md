# Lesson:mermaid 8.8 相容基線(通用;源=OctoAI 2026-08-26 連炸兩圖)

**環境事實**:本機 Markdown 預覽器=mermaid **8.8.0**(2020 年版)——新版語法直接炸
「Syntax error in graph」炸彈圖;圖炸掉=文件在 Sponsor 面前失效。**所有專案適用。**

**六條基線(畫任何 mermaid 前先過)**:
1. 只用 `graph TD/LR`,**禁 `flowchart`** 關鍵字。
2. 節點/邊文字**禁 `>` `<` `>=` `§`**(`>` 被誤解析成箭頭);「>=3」寫「3 條以上」。
3. **禁 `stateDiagram-v2`**(實測炸)——狀態機改 `graph TD`+邊標籤;note 改圖下文字。
4. **erDiagram 禁屬性區塊**(8.10 才支援)——關係線 only+欄位放 markdown 表格;
   或另出 SVG 實體檔引用。
5. sequenceDiagram 基本款(participant as/alt-else/autonumber)可用;`<br/>` 在 graph 節點可用。
6. **出圖後請 Sponsor 截圖確認渲染**——渲染成功不能用假設的。

替代路:gstack `/diagram`(excalidraw+SVG/PNG)不吃 mermaid 版本限制,複雜圖可走它。
機器守門:`scripts/loop_check.sh` 第 7 檢即本基線的自動掃描。
