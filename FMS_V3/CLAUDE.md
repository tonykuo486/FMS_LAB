# CLAUDE.md — FMS_V3 工廠管理系統(TypeScript 全棧)

> 給 AI 助手(Claude Code)與你自己的工程底冊。**AI 讀檔順序**:本檔 →
> [docs/SRS.md](docs/SRS.md)(每條編號=驗收項)→ [docs/SDD.md](docs/SDD.md)(怎麼做)
> → [docs/GUIDE.md](docs/GUIDE.md)(里程碑+踩坑)。
> 你的紀錄:[CHANGELOG.md](CHANGELOG.md)(時間軸)+[docs/99_決策紀錄_ADR.md](docs/99_決策紀錄_ADR.md)(決策)。

## Project Context

```
項目名稱    : FMS 工廠管理系統(程式設計專題;多據點生產任務排程)
技術棧      : TypeScript strict + Bun(Elysia 後端/Refine+AntD5+Vite 前端)+ PostgreSQL 17
              ★版本=SDD §11 鎖定表死版號,bun.lock 為唯一真相
主要目的    : SRS 全部需求編號逐條達成(FACT/TASK/PERS/ACC)
Run  指令  : cd infra && docker compose up -d(PG;首次 cp .env.example .env)
              backend `bun run --watch src/index.ts`(3000)/ frontend `vite`(5173,/api proxy)
Test 指令   : bun test(測試庫 fms_test,禁連開發庫;每測試檔獨立)
Lint 指令   : bun run typecheck(專案內 tsc 5.9.3;禁裸 bun x tsc)
交付        : docker compose up -d 一鍵起(SRS TECH-13/ACC-7)
```

## 鐵律(違反=驗收不過;AI 也不准繞)

1. **後端守衛才是安全**——前端擋按鈕不算數;每端點 JWT+角色檢查(TECH-9)。
2. **資料庫約束才是底**——排程衝突 service 檢查+EXCLUDE/unique 保底(TASK-6;ADR-0 示範)。
3. **完全離線禁 CDN**——不引外部字型/腳本(TECH-12;DevTools 零外部請求=ACC-6)。
4. **版本不准升**——套件版本照 SDD §11 死鎖;AI 不得自行 `bun add` 新版(升級走 §11 守則四綠燈)。
5. **SQL 一律參數化**($n),禁字串拼接;輸入雙層驗證(Elysia t+Zod)。
6. 匿名化在 **SQL/queryset 層**做,不在前端藏(PERS-24)。

## 與 AI 協作的節奏(這門課同時在教這個)

- 開工先讓 AI 讀 SRS 對應編號,要求它**引用編號**回答——避免它自由發揮。
- 每完成一個里程碑(GUIDE M1~M6):驗證綠 → 寫 CHANGELOG 條目(變化點+驗證證據)
  → commit(message=核實紀錄:現象→證據→修法→實測數字)。
- 重大設計選擇:要求 AI 列選項+代價,你拍板後記入 docs/99_決策紀錄_ADR.md(從 ADR-1 起)。
- AI 說「完成」不算數——照 GUIDE 的 Demo 劇本自己點過一遍才算(附錄 C)。
