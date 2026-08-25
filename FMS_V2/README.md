# FMS_V2 — 工廠管理系統（Python + Django 路線）

> **這是一份需求規格，不是一份可執行的專案。**
> 目錄裡沒有任何實作程式碼——`models.py`、`views.py`、`templates/`、`Dockerfile`
> 全部由**你**依 [`docs/SRS.md`](docs/SRS.md) 產出。這就是本次專題的作業內容。

**技術棧**：Python 3 ／ Django ／ SQLite ／ AdminLTE 3.2 ／ **uv**（套件管理）
**必讀**：[`docs/SRS.md`](docs/SRS.md)——第 2 章**每一條編號都是驗收項**。

---

## 開工前三件事

**1. 精讀 SRS 第 2 章。** TECH／FACT／TASK／PERS／ACC 每條編號都會被逐條打勾驗收。
特別是 **2.1.1 UI 版型規範**與 **2.1.2 Docker Compose 部署規格**——這兩節是硬規格，
不是建議。

**2. 先讀附錄 B 踩坑地圖。** ISO 第 53 週、排程 race condition、CSV 編碼（CP950）
是**必撞的三個**。開工前讀過，撞到時知道回來對號入座，能省下好幾個小時。

**3. 確認工具鏈。**

```bash
python --version     # 需 Python 3.12+（Dockerfile 基底為 python:3.12-slim）
uv --version         # 套件管理一律用 uv（TECH-1）
docker --version     # 驗收要跑 docker compose（TECH-13）
```

沒有 uv 就先裝（一行，跨平台）：

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```
```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## uv 速查（TECH-1：不使用裸 pip/venv）

| 你要做的事 | 指令 |
|---|---|
| 開專案 | `uv init` |
| 加依賴 | `uv add django` |
| 加開發依賴 | `uv add --dev pytest-django` |
| 還原環境（照 `uv.lock`） | `uv sync` |
| 跑指令（免手動 activate） | `uv run python manage.py migrate` |
| 跑 Django dev server | `uv run python manage.py runserver` |
| 跑測試（TECH-8） | `uv run python manage.py test` |
| 匯出 wheelhouse（TECH-12 離線） | `uv export --format requirements-txt > requirements.txt`<br>`uv pip download -d wheels/ -r requirements.txt` |

> **`uv.lock` 要進版控。** 它是「環境可重現」的唯一真相——助教在自己機器上
> `uv sync` 必須還原出和你一模一樣的環境，否則「在我電腦上會動」不算數。

## 交付門檻（照這個順序自測）

1. **附錄 A 里程碑 M1~M6** 逐項完成——commit 歷史要看得出節奏（最後一天一包 zip 直接扣分）。
2. **附錄 C Demo 劇本**自己走一遍——老師抽查用的是同一份，10 分鐘走位。
3. **ACC-6 斷網驗收**：拔網路線／關 Wi-Fi，全功能仍可展示，DevTools Network 零外部請求。
4. **ACC-7 Compose 驗收**：`docker compose up -d` 三步啟動；`down` 再 `up` 後**資料仍在**。

---

## 轉交：推到你自己的 GitHub

本目錄目前是教材 repo（`FMS_LAB`）的一部分。你的作業要有**自己的 repo、自己的 commit
歷史**，所以第一步是把 V2 抽成獨立專案，而不是在教材 repo 上開分支。

### 步驟 1：抽出成獨立專案

```bash
# 在 FMS_LAB 之外的位置（例如 ~/projects）
mkdir fms-v2 && cd fms-v2
cp -r /path/to/FMS_LAB/FMS_V2/. .     # Windows PowerShell: Copy-Item -Recurse ...\FMS_V2\* .
```

複製過來的只有 `README.md` 與 `docs/SRS.md`——**這是正常的**，其餘全部是你要寫的。

### 步驟 2：git init（**注意兩個坑**）

```bash
git init -b main

# ★坑1：公開 repo 別用私人/公司信箱——用 GitHub noreply 信箱
git config user.email "<你的帳號>@users.noreply.github.com"
git config user.name  "<你的帳號>"

# ★坑2：先寫 .gitignore 再 add
#   data/、wheels/、.venv/、__pycache__/ 進了歷史就很難清
cat > .gitignore <<'GITIGNORE'
.venv/
__pycache__/
*.py[cod]
data/              # SQLite 落在 volume,不進版控
wheels/            # 離線 wheelhouse,體積大且可由 uv.lock 重建
staticfiles/       # collectstatic 產物
.env
GITIGNORE

git add -A && git commit -m "chore: 專案初始化（SRS + README + gitignore）"
```

> `uv.lock` **要**進版控（環境可重現）；`.venv/` 與 `wheels/` **不進**（可重建、體積大）。

### 步驟 3：建遠端 repo 並推送

```bash
gh repo create <你的帳號>/fms-v2 --private --source . --remote origin --push
```

一條指令＝建 repo＋設 remote＋push。作業一律先 `--private`；要給老師看再加協作者，
或 `gh repo edit --visibility public`。

沒裝 GitHub CLI 或還沒認證，見教材根目錄 [`../README.md`](../README.md) 的
「附：GitHub 上傳與認證程序」——那一節每一步都實測過。

### 步驟 4：核實（推完必做）

**不是「看起來成功」，而是「驗過一致」**：

```bash
git ls-remote origin main     # 遠端 commit hash
git log --oneline -1          # 本地 commit hash —— 兩者必須相同
gh repo view --json visibility,url,defaultBranchRef
```

> **上傳前最後一關**：`grep` 全 repo 掃一遍不該公開的字串（公司網域／內網 IP／
> 帳密／客戶名）。這一步養成習慣，比事後刪 commit 便宜一萬倍。

---

*需求有疑義以 [`docs/SRS.md`](docs/SRS.md) 為準；SRS 與本檔衝突時，以 SRS 為準。*
