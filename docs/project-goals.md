# Project Goals

## 最終目標

SwGraphUI の最終目標は、[React Flow Examples](https://reactflow.dev/examples) に掲載されている examples を SwiftUI 向けライブラリとして実装し、SwiftUI ネイティブな API で再現可能にすることです。

## 目標の意味

- 単なる見た目の模倣ではなく、インタラクション、ノード/エッジモデル、レイアウト、ツールバー、ズーム、選択、接続、サブフローなどの振る舞いを再現する
- 参照元は React 実装だが、SwiftUI 側では Swift の型安全性と宣言的 UI に沿った API を設計する
- examples の実装は、ライブラリ本体の API 妥当性を検証する受け入れ基準として扱う
- 受け入れ確認のため、パッケージ内に examples を実行できる SwiftUI アプリ target を持つ

## 完了条件

- `reactflow.dev/examples` の Examples セクションにある全 examples を SwiftUI で再現できる
- 同ページの UI セクションにある再利用可能コンポーネント群についても、SwiftUI 向け API として表現方針を定義する
- 各 example に対して、対応する SwGraphUI サンプルまたはテストハーネスが存在する
- ライブラリ利用者が React Flow の主要ユースケースを SwiftUI 上で置き換えられる
- 拡張フェーズとして、印刷/PDF・PNG エクスポートを提供し、拡大時の文字ぼやけに配慮した出力品質要件を満たす

## ソース・オブ・トゥルース

- 公開 examples 一覧: [https://reactflow.dev/examples](https://reactflow.dev/examples)
- 参照実装リポジトリ: [xyflow/xyflow](https://github.com/xyflow/xyflow)
- ローカル参照クローン: `/Users/kentaro/Projects/SwGraphUI/.reference/xyflow`
- 確認用アプリ target: `/Users/kentaro/Projects/SwGraphUI/Example`

## 現時点の前提

- 公開ページ確認日: 2026-04-04
- 公開ページ上の Examples セクション最終更新: 2026-03-19
- 公開ページ上の core examples 数: 66
- ローカル `xyflow` の React examples ルート数: 65

この差分は、公開サイトの examples 構成と、ローカル参照リポジトリ内の開発用 examples ルーティングが完全一致しないことを示している。以後の実装計画では、まず公開サイト基準で目録管理し、実装調査はローカル clone を補助的に使う。

## 1.0 Gate 判定基準 (Stable Quality Standard)

1.0 リリースの Gate 通過可否は、以下の品質原則と具体的な未完了作業の両面から判定する。

### 1. Quality Principles (不変の品質原則)
- **Core Correctness**: 選択、階層、制約、レイアウト、Undo/Redo 等のコア機能が、単体テストおよび統合環境で回帰なく動作すること。
- **Runtime Stability**: 大規模グラフ操作、ズーム、アニメーション等の、高負荷時や極端な Viewport 状況下で致命的なクラッシュやフリーズがないこと。
- **Docs Trustworthiness**: 公開 API のシグネチャと README のサンプルコードが 100% 同期しており、導入手順が配布実態と矛盾しないこと。

### 2. Open Tasks (1.0 向け残存 Must タスク)
- [ ] **新 API 検証の完遂**: 階層更新等の新規公開経路に対する、コードレベルでの直接的な回帰テストの追加。
- [ ] **配布・タグ実態の確定**: リポジトリ公開 URL および 1.0.0 タグの運用方針、README の最終固定。

### 3. Deferred (1.1+ 以降へ送る責務)
- Accessibility 実機検証 (VoiceOver/Inspector 最終判定)
- 高度なアクセシビリティ設計

### 現在のステータス (M38 終了時点判定)
- **M38 完了**: Yes (Hardening 目標達成)
- **1.0 Candidate**: Yes (主要機能・安定性良好)
- **1.0 Gate 通過**: No (**「ほぼ到達、でも未通過」**)
