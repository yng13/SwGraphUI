# SwGraphUI Agent Instructions

## Language
- ユーザー向け回答は日本語
- ドキュメントは日本語
- コードコメントも原則日本語

## Project context
- このリポジトリは公開可能な Swift Package `SwGraphUI`


## 運用ルール

- 目標のソース・オブ・トゥルースは `reactflow.dev/examples` とする
- 実装差分の調査には `.reference/xyflow` を参照実装として使う
- examples の追加、削除、再分類が発生した場合は `examples-inventory.md` を先に更新する
- リモートリポジトリは存在しない。`git push` は絶対に行わず、ローカルでのコミットを最終工程とする。

## Required reading

- `project-goals.md`: プロジェクトの最終目標と達成基準
- `architecture.md`: ライブラリ設計方針と実装原則
- `responsibility-boundaries.md`: コンポーネント責務境界
- `d3-dependency-analysis.md`: d3 依存の責務分解
- `system-migration-order.md`: core-first の移植順
- `framework-responsibility-analysis.md`: system / react / svelte の責務整理
- `package-layout.md`: package ディレクトリ構成案
- `examples-inventory.md`: React Flow examples の棚卸し
- `backlog.md`: 実装バックログと優先順位

Also use these role playbooks when relevant:
- playbooks/requirements-planner.md
- playbooks/dev-engineer.md
- playbooks/qa-analyst.md
- playbooks/code-reviewer.md

## Working rules
- 基底フェーズでは pure Swift を優先する
- SwiftUI / platform adapter / AppKit bridge は明示指示があるまで後回し
- React 固有 abstraction は模倣しない
- `@xyflow/system` を logic reference とする
- `@xyflow/svelte` を UI/behavior reference とする
- 参照 repo は、可能な限りローカル clone `/.reference/xyflow` を優先して使う
- 参照 commit は `docs/reference-lock.md` に固定し、更新したら同ファイルも更新する
- phase の入口だけでなく、局所修正の前にも該当箇所を都度再参照する
- 特に edge rendering / marker / animation / label / connect-handle affordance は詳細レベルで再参照する
- EasyCompose 固有 field を public model に入れない
- 一度に大きく実装しない
- backlog から 1 マイルストーンずつ進める
- 宙に浮く未実装を残さない
- 今回で閉じない項目は、後続マイルストーンの責務として明示してから送る
- `残課題` は単なる TODO リストではなく、`今回で閉じる項目` か `後続へ送る責務` に必ず分解する
- docs 更新だけでは停止しない
- 停止してよいのは `実装タスク` `レビュー` `コミット` の直前だけ

## Validation
- 変更後は `swift test` を実行する
- 失敗したら原因を簡潔に説明する
- 各マイルストーン完了時に self-review を行う
- 報告では必ず以下を含める:
  - 変更ファイル
  - 変更理由
  - テスト結果
  - 今回で閉じたこと / 後続へ送る責務
  - backlog/current-plan の更新内容
  - 次の自然なタスク

## Review behavior
- 実装前に requirements-planner の観点で scope を確認する
- 実装時は dev-engineer の観点で最小差分を優先する
- テスト追加時は qa-analyst の観点で抜け漏れを確認する
- 完了時は code-reviewer の観点で自己レビューする
- 次の変更では、実装後にレビュー提案を行う:
  - public API を変更したとき
  - レイヤー境界を跨ぐとき（例: Core -> Controller, Controller -> View）
  - 状態管理ロジックを変更したとき（例: viewport, connect state machine）
- 次の軽微な変更では、レビュー提案を必須にしない:
  - テスト追加のみ
  - minor refactor
  - コメント修正
