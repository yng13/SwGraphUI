# Current Plan

## 現在のマイルストーン

M4: core-first 移植順の固定

## Scope summary

- `@xyflow/system` を依存強度で分類する
- 初回マイルストーンとして移す pure core 範囲を固定する
- まだ Swift 実装そのものには入らない

## Included

- `docs/system-migration-order.md` の追加
- `docs/architecture.md` の更新
- `docs/backlog.md` の更新

## Excluded

- `system` 外部依存全体の Swift 置換設計
- `svelte` 優先参照の妥当性評価
- Swift Package の public API 追加
- examples 実装そのもの

## Risks

- Tier 0 と Tier 1 の境界を雑に切ると後で型が揺れる
- `types/nodes.ts` のような mixed file をそのまま移すと DOM 型が混ざる
- pure utility を広く取りすぎると初回マイルストーンが肥大化する

## Recommended next implementation step

`system-migration-order.md` を基準に、初回マイルストーンの core model / pure utility を実際の Swift 型へ落とし込む
