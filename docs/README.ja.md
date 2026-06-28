<div align="center">

# 🧭 autoskills

**[Claude Code](https://claude.com/claude-code) のためのメタスキル —— _最適なスキルを見つけるためのスキル。_**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-d97757)](https://claude.com/claude-code)
[![Type](https://img.shields.io/badge/type-skill-8A2BE2)](../SKILL.md)
[![Install](https://img.shields.io/badge/install-npx%20skills-CB3837?logo=npm&logoColor=white)](https://www.npmjs.com/package/skills)

[English](../README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · **日本語** · [한국어](README.ko.md)

</div>

---

`autoskills` は、エンジニアリング上の課題、コードベース、あるいは現在のタスクを受け取り、**ローカルのスキルライブラリ**と**オンラインのエコシステム**の両方から最も適したスキルを見つけ出し、ひとつのランキングにまとめて提示します。各候補を明確な品質ルーブリックで評価し、最適なものを推薦したうえで、有効だった結果を永続的なレジストリに記録するため、その後の検索はどんどん賢くなります。推薦後には、対象リポジトリの `CLAUDE.md` に自動メンテナンスされるリマインダーを書き込み、そのリポジトリでの今後のセッションがそれらのスキルを自動的に使うようにすることもできます。

オンライン検索のみに対応した `find-skills` スキルに対して、ローカル検索・スコアリング・永続的なメモリを追加し、これを置き換えます。

## ✨ 特長

- **ローカル + オンライン検索** —— 呼び出し可能なローカルスキルと `npx skills` エコシステムの両方から候補を集め、まとめてランキングします。
- **品質ルーブリック** —— 各候補を Fit（適合度）、Trust（信頼性）、Track-record（実績）、Freshness（鮮度）、Specificity（具体性）の観点でスコア付けし、読み取れない／プレースホルダーだけのスキルを除外するサニティチェックを備えています。
- **永続的なメモリ** —— ハイブリッドなレジストリ（グローバルストア + プロジェクトごとに 1 行のポインタ）が、どのスキルがどの課題を解決したかを記憶します。
- **可用性を考慮** —— いま実際に使えるスキルだけを推薦します。「優先したいが未同期」のスキルは、推薦せずにカタログに記録します。
- **リポジトリ内リマインダー** —— 同意のもとで冪等な `CLAUDE.md` ブロックを書き込み、そのリポジトリの今後のエージェントが使うべきスキルを把握できるようにします。

## 📦 インストール

`autoskills` は Claude Code のスキルです。[`skills`](https://www.npmjs.com/package/skills) CLI でインストールします。

```bash
npx skills add B143KC47/autoskills -g -a claude-code -y
```

または手動でインストールします。

```bash
git clone https://github.com/B143KC47/autoskills.git
cp -r autoskills ~/.claude/skills/autoskills
```

これで `Skill` ツールから利用できるようになります。インストール先のフォルダは、`~/.claude/skills/autoskills/registry/` にあるグローバルレジストリのホームも兼ねています。

## 🚀 使い方

スキルを探したいときにいつでも呼び出してください。

- 「X にはどのスキルを使えばいい？」 /「X のためのスキルを探して」 /「X ができるスキルはある？」
- リポジトリ／フォルダを指して、どのスキルが当てはまるか尋ねる。
- 課題（リサーチ、ファインチューニング、評価、UI、デバッグ……）に取りかかるとき、スキルが役立ちそうな場面で。

8 ステップのワークフロー: 入力モードを判定 → メモリを参照 → ローカル + オンラインの候補を収集 → ルーブリックで評価・ランキング → 上位 3〜5 件を提示 → 決定 → 結果を記録 → リポジトリ内 `CLAUDE.md` リマインダーを提案。詳細は [`SKILL.md`](../SKILL.md) を参照してください。

## 💡 例

> **あなた：**「技術トピックについて、引用付きで深く掘り下げるリサーチ向けのスキルを探して」

`autoskills` はレジストリから過去の成功例を思い出し、ローカル**と**オンラインの候補を集め、ルーブリックでそれぞれをスコア付けし、ひとつのランキングで回答します。

```text
1. deep-research · local · 9/10 Strong · ファンアウト型のウェブ検索、敵対的なファクトチェック、
   引用付きレポート —— 要望に合致 · すでに呼び出し可能
2. find-skills   · local · 5/10 Decent · スキルの発見/インストールは可能だがオンライン限定、
   統合機能なし · 呼び出し可能
   …オンライン候補も同じランキングにスコア付けされ、それぞれに `npx skills add …` の行が付きます
```

`autoskills` は **deep-research** を推薦し、この成功を記録するので、次のリサーチ系クエリはより速くランク付けされます —— さらに `CLAUDE.md` リマインダーの書き込みを提案し、そのリポジトリの今後のセッションが自動的にそれを思い出すようにします。

## 🗂️ リポジトリ構成

| パス | 役割 |
|---|---|
| `SKILL.md` | オーケストレーションのワークフロー（エントリーポイント） |
| `references/` | ルーブリック、レジストリ形式、フォルダスキャンのマップ、`CLAUDE.md` の手順 |
| `scripts/` | 任意の依存関係なし Node ヘルパー（ローカルインデックス；`CLAUDE.md` の upsert） |
| `registry/` | 初期データ入りの「課題 → スキル」レジストリ |
| `tests/` | ドキュメント向けの Bash チェックと、スクリプト向けの振る舞いテスト |

## 🛠️ 開発

Bash と Node.js が必要です（npm 依存関係はありません）。フルスイートを実行します。

```bash
bash tests/check-integration.sh   # すべてのドキュメントチェック + 振る舞いテストを実行
```

## 📄 ライセンス

Apache License, Version 2.0 のもとでライセンスされています —— [`LICENSE`](../LICENSE) と [`NOTICE`](../NOTICE) を参照してください。

Copyright © 2026 KO Ho Tin.
