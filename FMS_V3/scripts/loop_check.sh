#!/usr/bin/env bash
# loop_check — 閉環健檢模板(目標→驗收→回饋的機器版;過閘憑據之一)
# 來源:OctoAI 2026-08-26 實戰(首跑即自抓檢查器誤判一次——檢查器本身也要被驗)
# 用法:cp 後依專案調整路徑與檢查項;bash scripts/loop_check.sh;紅燈=exit 1
# 原則:寫在文件裡的 loop 誰都會漂,能讓紅燈擋住你的才是真閉環。
set -u
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
ok(){ echo "  ✅ $1"; PASS=$((PASS+1)); }
ng(){ echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "═══ loop_check ═══"

# 1. 需求圈:SRS 條數 = COMPLIANCE 宣稱基線(改需求沒同步基線→紅燈)
if [ -f docs/SRS.md ] && [ -f docs/COMPLIANCE.md ]; then
  srs_n=$(grep -oE '\*\*[A-Z]+-[0-9]+\*\*' docs/SRS.md | sort -u | wc -l)
  base_n=$(grep -oE '[0-9]+%\([0-9]+/[0-9]+\)' docs/COMPLIANCE.md | head -1 | grep -oE '/[0-9]+' | tr -d '/')
  [ "$srs_n" = "$base_n" ] && ok "SRS 條數($srs_n)=COMPLIANCE 基線($base_n)" || ng "SRS $srs_n ≠ 基線 $base_n"
fi

# 2. 需求圈:todo 有勾項時 COMPLIANCE 不得無 Evidence(不回寫=不算完)
done_n=$(grep -c '^\- \[x\]' tasks/todo.md 2>/dev/null || echo 0)
evid_n=$(grep -c '✅' docs/COMPLIANCE.md 2>/dev/null || echo 0)
if [ "$done_n" -gt 0 ] && [ "$evid_n" -le 1 ]; then ng "todo 勾 $done_n 但 COMPLIANCE 無 Evidence"; else ok "需求圈回寫(勾 $done_n/✅ $evid_n)"; fi

# 3. 執行圈:CHANGELOG 有合規日期條目
grep -qE '^## 20[0-9]{2}-[0-9]{2}-[0-9]{2}' CHANGELOG.md 2>/dev/null && ok "CHANGELOG 有日期條目" || ng "CHANGELOG 無日期條目"

# 4. 學習圈:lessons 非空殼(被糾正要立刻寫)
[ "$(grep -vcE '^#|^\s*$' tasks/lessons.md 2>/dev/null || echo 0)" -gt 0 ] && ok "lessons 有內容" || ng "tasks/lessons.md 空殼"

# 5. WBS 紀律:工項列驗收欄非空(依專案調整工項編號樣式,如 W0.x/C1.x)
#    範例(cp 後改路徑與樣式):
# noacc=$(grep -E '^\| *(W[0-9]+\.[0-9]+)' docs/PLAN_TOGAF/05_*.md | awk -F'|' '{...}')

# 6. 斷鏈偵測:PLAN 內相對連結目標存在(索引制文件的命門)
if ls docs/PLAN_TOGAF/*.md >/dev/null 2>&1; then
  miss=0
  while IFS= read -r f; do
    [ -e "docs/PLAN_TOGAF/$f" ] || [ -e "docs/$f" ] || { miss=$((miss+1)); echo "     斷鏈: $f"; }
  done < <(grep -ohE '\]\((\.\./)?[^)#http][^)#]*\.md' docs/PLAN_TOGAF/*.md 2>/dev/null | sed -E 's/^\]\(//; s/^\.\.\///' | sort -u)
  [ "$miss" = "0" ] && ok "PLAN 連結零斷鏈" || ng "斷鏈 $miss 個"
fi

# 7. mermaid 8.8 基線(見 lessons/mermaid-88-相容基線.md;預覽器炸圖=文件在 Sponsor 面前失效)
viol=$(grep -rnE '^\s*(flowchart|stateDiagram-v2)' docs --include='*.md' 2>/dev/null | wc -l)
[ "$viol" = "0" ] && ok "mermaid 8.8 基線" || ng "mermaid 8.8 違規 $viol 處"

echo "─────────────────────────"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && { echo "✅ 閉環健檢全綠"; exit 0; } || { echo "❌ 閉環有洞,修完再過閘"; exit 1; }
