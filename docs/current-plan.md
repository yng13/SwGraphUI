# Current Plan

## 現在のマイルストーン

M8: pure core の初回完了

## Scope summary

- `Sources/SwGraphUI` の最小ディレクトリ構成を実際に切る
- pure core の最初の型を追加する
- utility と runtime state の placeholder を実体化する
- 宙に浮く未実装を作らず、送るものは後続責務として明示する

## Included

- `Sources/SwGraphUI/Core/Model/*`
- `Sources/SwGraphUI/Core/Algorithms/*`
- `Sources/SwGraphUI/Runtime/State/*`
- `Sources/SwGraphUI/Public/API/*`
- `Sources/SwGraphUI/Public/Types/*`
- `Tests/SwGraphUITests/*`

## Excluded

- `system` 外部依存全体の Swift 置換設計
- interaction engine の実装
- examples 実装そのもの

## Exit rule

- このマイルストーンの範囲で生じた未実装は、可能な限りこのマイルストーン内で閉じる
- 次へ送る場合は、`次の責務` と `受け入れ条件` を backlog に追加してから送る

## Risks

- `GraphNode / GraphEdge` の generic public surface は今後も微調整余地がある
- interaction engine に入ると Runtime/State の再分割が必要になる可能性がある
- viewport fit や transform utility はまだ拡張余地がある

## Recommended next implementation step

`Core/Interaction` の責務境界を定義し、interaction engine に着手する
