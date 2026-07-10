<div align="center">

# 🧭 autoskills

**面向 [Claude Code](https://claude.com/claude-code) 的元技能 —— _一个用来寻找合适技能的技能。_**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-d97757)](https://claude.com/claude-code)
[![Type](https://img.shields.io/badge/type-skill-8A2BE2)](../SKILL.md)
[![Install](https://img.shields.io/badge/install-npx%20skills-CB3837?logo=npm&logoColor=white)](https://www.npmjs.com/package/skills)

[English](../README.md) · **简体中文** · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

</div>

---

`autoskills` 接收一个工程问题、一个代码库或你当前的任务，然后从你的**本地技能库**和**在线生态**中找出最匹配的技能 —— 两者会被合并到同一个排序列表中。它依据一套明确的质量评分标准来评估每个候选项，推荐最合适的那一个，并把有效的结果写入持久化注册表，让之后的搜索越来越聪明。在给出推荐之后，它还可以在目标仓库的 `CLAUDE.md` 中写入一段自动维护的提示，让该仓库后续的会话自动使用这些技能。

它在仅支持在线搜索的 `find-skills` 技能之上，新增了本地搜索、评分与持久化记忆，从而取代了后者。

## ✨ 特性

- **本地 + 在线搜索** —— 同时从你可调用的本地技能与 `npx skills` 生态中收集候选项，并合并排序。
- **多智能体深度搜索** —— 在 Claude Code 中，在线发现以 `Workflow` 方式运行：多个 Sonnet 查找器并行扫描四个角度（生态、排行榜、GitHub、新发布），随后由 Opus 验证器逐一对抗式评分（先抓取候选技能的真实内容再判断）。在只有子智能体的环境中平滑降级；在没有子智能体的环境（如 Codex）中退化为完全顺序化流程。
- **质量评分标准** —— 从契合度（Fit）、可信度（Trust）、过往表现（Track-record）、新鲜度（Freshness）与针对性（Specificity）五个维度为每个候选项打分，并通过一道完整性校验剔除无法读取或仅有占位内容的技能。
- **配置门控的自动安装** —— 在 `config.json` 中设置 `auto_install: true` 后，经 Opus 验证为 **Strong** 且可信度达标（`trust_floor` 默认 2：知名作者或 1K+ 安装量）的技能会被自动安装并使用 —— 始终报告、绝不静默，且安装/使用前必先检查其内容是否含可疑指令。默认关闭。
- **持久化记忆** —— 一套混合式注册表（全局存储 + 每个项目一行的指针），记住哪些技能解决过哪些问题。
- **可验证的反馈闭环** —— 工作完成时，智能体自评每个技能是否真正有帮助；失败会以客观、有证据支撑的结果记录写入注册表，供后续排序读取。
- **可用性感知** —— 只推荐当前可直接使用的技能；对那些“优先但尚未同步”的技能则只登记而不推荐。
- **仓库内提示** —— 可在征得同意后，向仓库写入一段幂等的 `CLAUDE.md` 区块，让该仓库后续的智能体知道该用哪些技能。

## 🔍 工作原理

```mermaid
flowchart TD
    A["🎯 你的问题 · 仓库 · 当前任务"] --> B["📇 读取配置 &<br/>查询注册表记忆"]
    B -->|"⚡ 快速路径：注册表已知<br/>一个 Strong 且可调用的匹配"| P
    B --> C["🗂️ 收集并评分<br/>本地候选"]
    C -->|"本地已有 Strong 匹配"| M
    C -->|"无 Strong 匹配，<br/>或你要求在线搜索"| DS

    subgraph DS ["🌐 深度搜索 —— 多智能体"]
        direction TB
        F1["🔎 Sonnet 查找器<br/>npx skills find"]
        F2["🏆 Sonnet 查找器<br/>skills.sh 排行榜"]
        F3["🐙 Sonnet 查找器<br/>GitHub SKILL.md 搜索"]
        F4["✨ Sonnet 查找器<br/>新发布"]
        F1 & F2 & F3 & F4 --> DD["🧹 去重 · 预排序 ·<br/>按 max_verify 截断"]
        DD --> V["🔬 Opus 验证器<br/>抓取真实内容 · 对抗式评分 ·<br/>可疑内容检查"]
    end

    V --> M["⚖️ 合并排序<br/>同一列表，0–10 分"]
    M --> P["🏅 呈现前 3–5 名"]
    P --> Q{"决定"}
    Q -->|"auto_install: true<br/>Strong + 可信 + 无可疑内容"| R["📦 安装并使用<br/>（始终报告）"]
    Q -->|"默认"| S["💬 推荐 ·<br/>提议安装"]
    R --> T
    S --> T["📝 记录结果<br/>客观、可验证的记录"]
    T --> U["🧭 提议写入仓库内<br/>CLAUDE.md 提示"]
    T -. "过往表现反馈<br/>到未来排序" .-> B
```

在 Claude Code 中全速运行，在其他环境中平滑降级：

| 层级 | 环境 | 执行方式 |
|---|---|---|
| 🟢 **Workflow** | Claude Code（`Workflow` 工具） | 并行 Sonnet 查找器 + 每个候选一个对抗式 Opus 验证器 |
| 🟡 **Agent** | 任何支持子智能体的环境 | 并行查找器智能体 + 单个 Opus 级验证智能体 |
| 🔵 **Inline** | 无子智能体（如 Codex） | 相同的角度与评分标准，由智能体自身顺序执行 |

## 📦 安装

`autoskills` 是一个 Claude Code 技能。使用 [`skills`](https://www.npmjs.com/package/skills) CLI 安装：

```bash
npx skills add B143KC47/autoskills -g -a claude-code -y
```

或手动安装：

```bash
git clone https://github.com/B143KC47/autoskills.git
cp -r autoskills ~/.claude/skills/autoskills
```

随后它即可被 `Skill` 工具调用。安装目录同时也是位于 `~/.claude/skills/autoskills/registry/` 的全局注册表主目录。

## 🚀 用法

当你想找一个技能时，随时调用它：

- “我该用哪个技能来做 X？” / “帮我找一个做 X 的技能” / “有没有能做 X 的技能？”
- 把它指向某个仓库/文件夹，问哪些技能适用。
- 着手一个问题（研究、微调、评估、UI、调试……）时，某个技能可能会有帮助。

工作流：解析技能根目录 + 读取配置 → 查询记忆（注册表已有强匹配时走快速路径；你明确要求在线搜索时该路径失效）→ 收集并评分本地候选 → 深度搜索在线候选（仅当本地无 Strong 匹配、或你明确要求在线搜索时）→ 合并排序 → 呈现前 3–5 名 → 做出决定（按配置自动安装）→ 以可验证的记录写入结果 → 提议在仓库内写入 `CLAUDE.md` 提示。完整细节见 [`SKILL.md`](../SKILL.md)。

### ⚙️ 配置

在 `SKILL.md` 旁创建 `config.json`（参见 [`config.json.example`](../config.json.example)）：

```jsonc
{
  "auto_install": false,   // true → 无需询问即安装并使用经验证的 Strong 技能
  "min_tier": "strong",    // 自动安装的层级下限（"strong" | "decent"）
  "trust_floor": 2,        // 自动安装所需的可信度分数（2 = 知名作者 / 1K+ 安装量）
  "finders": 4,            // 深度搜索工作流中的并行查找器数量
  "max_verify": 10         // 每次搜索的验证上限（被舍弃的候选一定会记录）
}
```

## 💡 示例

> **你：**“帮我找一个能对技术主题做深度、带引用的研究的技能”

`autoskills` 会从注册表中回忆过往成功案例，收集本地**和**在线候选，依据评分标准逐一打分，并以一个排序列表作答：

```text
1. deep-research · local · 9/10 Strong · 扇出式网络搜索、对抗式事实核查、
   带引用的报告 —— 与需求匹配 · 已可调用
2. find-skills   · local · 5/10 Decent · 能发现/安装技能，但仅限在线、
   无综合能力 · 可调用
   …在线候选会被打分进同一个列表，每一项都附带其 `npx skills add …` 命令行
```

它会推荐 **deep-research**，并记录这次成功，让下一次研究类查询排得更快 —— 同时提议写入一段 `CLAUDE.md` 提示，让该仓库后续的会话自动想到它。

## 🗂️ 仓库结构

| 路径 | 用途 |
|---|---|
| `SKILL.md` | 编排工作流（入口） |
| `references/` | 评分标准、深度搜索工作流模板、注册表格式、文件夹扫描映射、`CLAUDE.md` 流程 |
| `config.json.example` | 配置模式（自动安装门控、查找器数量） |
| `scripts/` | 可选的零依赖 Node 辅助脚本（本地索引；`CLAUDE.md` 写入/更新） |
| `registry/` | 预置的「问题 → 技能」注册表 |
| `tests/` | 针对文档的 Bash 检查与针对脚本的行为测试 |

## 🛠️ 开发

需要 Bash 与 Node.js（无 npm 依赖）。运行完整测试套件：

```bash
bash tests/check-integration.sh   # 运行所有文档检查 + 行为测试
```

## ⭐ 支持

如果 autoskills 帮你找到了合适的技能，欢迎[**给仓库点个 Star**](https://github.com/B143KC47/autoskills) —— 让更多智能体找到属于它们的技能。

## 📄 许可证

基于 Apache License 2.0 版授权 —— 详见 [`LICENSE`](../LICENSE) 与 [`NOTICE`](../NOTICE)。

版权所有 © 2026 KO Ho Tin。
