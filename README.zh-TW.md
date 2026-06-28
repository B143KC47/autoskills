<div align="center">

# 🧭 autoskills

**為 [Claude Code](https://claude.com/claude-code) 打造的元技能 —— _一個用來尋找合適技能的技能。_**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-d97757)](https://claude.com/claude-code)
[![Type](https://img.shields.io/badge/type-skill-8A2BE2)](SKILL.md)
[![Install](https://img.shields.io/badge/install-npx%20skills-CB3837?logo=npm&logoColor=white)](https://www.npmjs.com/package/skills)

[English](README.md) · [简体中文](README.zh-CN.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md)

</div>

---

`autoskills` 接收一個工程問題、一個程式碼庫或你當前的任務，接著從你的**本地技能庫**與**線上生態**中找出最匹配的技能 —— 兩者會被合併到同一個排序清單中。它依據一套明確的品質評分標準來評估每個候選項，推薦最合適的那一個，並把有效的結果寫入持久化註冊表，讓之後的搜尋越來越聰明。在給出推薦之後，它還能在目標儲存庫的 `CLAUDE.md` 中寫入一段自動維護的提示，讓該儲存庫後續的工作階段自動使用這些技能。

它在僅支援線上搜尋的 `find-skills` 技能之上，新增了本地搜尋、評分與持久化記憶，從而取代了後者。

## ✨ 特性

- **本地 + 線上搜尋** —— 同時從你可呼叫的本地技能與 `npx skills` 生態中收集候選項，並合併排序。
- **品質評分標準** —— 從契合度（Fit）、可信度（Trust）、過往表現（Track-record）、新鮮度（Freshness）與針對性（Specificity）五個面向為每個候選項評分，並透過一道完整性檢查剔除無法讀取或僅有佔位內容的技能。
- **持久化記憶** —— 一套混合式註冊表（全域儲存 + 每個專案一行的指標），記住哪些技能解決過哪些問題。
- **可用性感知** —— 只推薦當前可直接使用的技能；對那些「優先但尚未同步」的技能則只登錄而不推薦。
- **儲存庫內提示** —— 可在徵得同意後，向儲存庫寫入一段冪等的 `CLAUDE.md` 區塊，讓該儲存庫後續的代理知道該用哪些技能。

## 📦 安裝

`autoskills` 是一個 Claude Code 技能。使用 [`skills`](https://www.npmjs.com/package/skills) CLI 安裝：

```bash
npx skills add B143KC47/autoskills -g -a claude-code -y
```

或手動安裝：

```bash
git clone https://github.com/B143KC47/autoskills.git
cp -r autoskills ~/.claude/skills/autoskills
```

隨後它即可被 `Skill` 工具呼叫。安裝目錄同時也是位於 `~/.claude/skills/autoskills/registry/` 的全域註冊表主目錄。

## 🚀 用法

當你想找一個技能時，隨時呼叫它：

- 「我該用哪個技能來做 X？」 /「幫我找一個做 X 的技能」 /「有沒有能做 X 的技能？」
- 把它指向某個儲存庫/資料夾，問哪些技能適用。
- 著手一個問題（研究、微調、評估、UI、除錯……）時，某個技能可能會有幫助。

8 步工作流程：辨識輸入模式 → 查詢記憶 → 收集本地 + 線上候選 → 用評分標準評估並排序 → 呈現前 3–5 名 → 做出決定 → 記錄結果 → 提議在儲存庫內寫入 `CLAUDE.md` 提示。完整細節見 [`SKILL.md`](SKILL.md)。

## 💡 範例

> **你：**「幫我找一個能對技術主題做深度、附引用的研究的技能」

`autoskills` 會從註冊表中回憶過往的成功案例，收集本地**與**線上候選，依據評分標準逐一評分，並以一個排序清單作答：

```text
1. deep-research · local · 9/10 Strong · 扇出式網路搜尋、對抗式事實查核、
   附引用的報告 —— 與需求匹配 · 已可呼叫
2. find-skills   · local · 5/10 Decent · 能發現/安裝技能，但僅限線上、
   無綜合能力 · 可呼叫
   …線上候選會被評分進同一個清單，每一項都附帶其 `npx skills add …` 命令列
```

它會推薦 **deep-research**，並記錄這次成功，讓下一次研究類查詢排得更快 —— 同時提議寫入一段 `CLAUDE.md` 提示，讓該儲存庫後續的工作階段自動想到它。

## 🗂️ 儲存庫結構

| 路徑 | 用途 |
|---|---|
| `SKILL.md` | 編排工作流程（入口） |
| `references/` | 評分標準、註冊表格式、資料夾掃描對應、`CLAUDE.md` 流程 |
| `scripts/` | 可選的零依賴 Node 輔助腳本（本地索引；`CLAUDE.md` 寫入/更新） |
| `registry/` | 預置的「問題 → 技能」註冊表 |
| `tests/` | 針對文件的 Bash 檢查與針對腳本的行為測試 |

## 🛠️ 開發

需要 Bash 與 Node.js（無 npm 相依套件）。執行完整測試套件：

```bash
bash tests/check-integration.sh   # 執行所有文件檢查 + 行為測試
```

## 📄 授權

採用 Apache License 2.0 版授權 —— 詳見 [`LICENSE`](LICENSE) 與 [`NOTICE`](NOTICE)。

著作權所有 © 2026 KO Ho Tin。
