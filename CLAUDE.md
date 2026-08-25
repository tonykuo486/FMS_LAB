# CLAUDE.md — FMS_LAB(教材維護視角)

> 本檔給**維護教材的人與 AI**;學員用的是各版內的 CLAUDE.md
> ([V2](FMS_V2/CLAUDE.md)/[V3](FMS_V3/CLAUDE.md))。

## 這個 repo 是什麼

同一份需求(編號一字不差)×兩個世代實作(V2 Django/V3 TS 全棧)的教學實驗室;
入口導覽見 [README.md](README.md),兩版對照見 [docs/V2_V3_對照表.md](docs/V2_V3_對照表.md)。

## 維護鐵律

1. **需求編號不可改語意**——兩版 SRS 的 FACT/TASK/PERS/ACC 必須永遠一字不差;
   改需求=兩版+對照表三處同步(README 頁尾維護約定)。
2. **每版三份文件分工不可混**:SRS(要什麼,實作中立)/SDD(怎麼做,換棧就重寫)/
   GUIDE(怎麼學)。往 SRS 塞技術細節=踩紅線。
3. **版本鎖定表(V3 SDD §11)是全家族基準**——OctoAI 等產品沿用;升級先在本教材
   實測四綠燈再外溢。
4. 學員三件套(CLAUDE/CHANGELOG/ADR)模板含示範條目——改模板時示範要跟著版本語境
   (V2=Django/V3=TS),別互相抄串。
5. 對外=GitHub tonykuo486/FMS_LAB(private);上傳前掃內部字樣(公司網域/內網 IP)
   ——本 repo 必須永遠可公開化。

## 常用檢核

```bash
grep -rn "giterp\|1\.1\.\d" --include=*.md .   # 內部字樣掃描(推前必跑)
git ls-remote origin main                        # 推後 hash 一致核實
```
