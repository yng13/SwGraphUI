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
