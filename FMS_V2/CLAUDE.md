# CLAUDE.md — FMS_V2 工廠管理系統(Python/Django)

> 給 AI 助手(Claude Code)與你自己的工程底冊。**AI 讀檔順序**:本檔 →
> [docs/SRS.md](docs/SRS.md)(每條編號=驗收項)→ [docs/SDD.md](docs/SDD.md)(怎麼做)
> → [docs/GUIDE.md](docs/GUIDE.md)(里程碑+踩坑)。
> 你的紀錄:[CHANGELOG.md](CHANGELOG.md)(時間軸)+[docs/99_決策紀錄_ADR.md](docs/99_決策紀錄_ADR.md)(決策)。

## Project Context

```
項目名稱    : FMS 工廠管理系統(程式設計專題;多據點生產任務排程)
技術棧      : Python 3 + Django + SQLite + AdminLTE(static/lib/ 離線資產)
              ★套件/虛擬環境一律 uv 管理(uv sync/uv run;不用裸 pip/venv;uv.lock=真相)
主要目的    : SRS 全部需求編號逐條達成(FACT/TASK/PERS/ACC)
Run  指令  : uv run manage.py migrate && uv run manage.py runserver
Test 指令   : uv run manage.py test
交付        : docker compose up -d 一鍵起(SRS TECH-13/ACC-7;離線 build 走 uv wheelhouse)
```

## 鐵律(違反=驗收不過;AI 也不准繞)

1. **後端守衛才是安全**——模板藏按鈕不算數;view 層登入+權限檢查(TECH-9)。
2. **資料庫約束才是底**——排程衝突 `clean()` 檢查+unique 保底(TASK-6;ADR-0 示範);
   且業務規則不可只掛 admin,一般 view 同一套(GUIDE §2 坑 6)。
3. **完全離線禁 CDN**——AdminLTE/jQuery/字型全走 `static/lib/`(TECH-12;ACC-6)。
4. **套件不准亂加/亂升**——一律 `uv add`+lock 進版控;AI 不得自行引新依賴。
5. ORM 天然參數化,但 `raw()`/`extra()` 禁用;表單輸入走 Django Forms 驗證。
6. 匿名化在 **queryset 層**做(annotate 別名),不在模板藏(PERS-24)。

## 與 AI 協作的節奏(這門課同時在教這個)

- 開工先讓 AI 讀 SRS 對應編號,要求它**引用編號**回答——避免它自由發揮。
- 每完成一個里程碑(GUIDE M1~M6):驗證綠 → 寫 CHANGELOG 條目(變化點+驗證證據)
  → commit(message=核實紀錄:現象→證據→修法→實測數字)。
- 重大設計選擇:要求 AI 列選項+代價,你拍板後記入 docs/99_決策紀錄_ADR.md(從 ADR-1 起)。
- AI 說「完成」不算數——照 GUIDE 的 Demo 劇本自己點過一遍才算(附錄 C)。
