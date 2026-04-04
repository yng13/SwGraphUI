# Package Layout Proposal

このファイルは、SwGraphUI の将来的なディレクトリ肥大化を前提に、`Sources/SwGraphUI` の構成案を固定するためのメモである。

## 目的

- `Sources/SwGraphUI` 直下のフラット化を防ぐ
- pure Swift core と UI / runtime / platform を分離する
- `system -> svelte -> example` の参照順に沿った構造にする

## 方針

- まず `Core` を最上位に置く
- その上に runtime と UI を積む
- platform 依存は端に寄せる
- examples 確認用 app は package library から明確に分離する

## 提案構成

```text
Sources/
  SwGraphUI/
    Core/
      Model/
      Algorithms/
      Interaction/
      Serialization/
    Runtime/
      State/
      Store/
      Selection/
      Viewport/
      Connection/
    UI/
      Container/
      Components/
        Nodes/
        Edges/
        Handles/
        Overlays/
      Plugins/
        Background/
        Controls/
        MiniMap/
        NodeToolbar/
        EdgeToolbar/
        NodeResizer/
    Platform/
      AppKit/
      UIKit/
      Shared/
    Public/
      API/
      Types/
      Builders/
    Internal/
      Adapters/
      Utilities/
      TestingSupport/
```

## 各ディレクトリの責務

### `Core/Model`

- `Node`, `Edge`, `Handle`, `Viewport`, `Rect` などの基礎型
- pure Swift

### `Core/Algorithms`

- geometry
- bounds
- graph traversal
- connection utility
- edge path
- marker 計算

### `Core/Interaction`

- drag engine
- pan/zoom engine
- connect engine
- resize engine

### `Core/Serialization`

- save/restore
- snapshot
- import/export 用 model 変換

### `Runtime/State`

- 実行時 state の定義
- lookup
- selection / hover / focus / transient state

### `Runtime/Store`

- state の保持戦略
- Observation 連携や internal store

### `Runtime/Selection`, `Viewport`, `Connection`

- 領域別 state と orchestration
- 将来肥大化したときの分離先

### `UI/Container`

- graph view 全体の組み立て
- layer 構成

### `UI/Components`

- node / edge / handle / overlay の view 実装

### `UI/Plugins`

- minimap, toolbar, controls, resizer などの追加 UI

### `Platform`

- AppKit / UIKit bridge
- cursor, clipboard, image export, native event 補助

### `Public/API`

- 利用者向け entry point
- public facade

### `Public/Types`

- 公開してよい型だけを再配置

### `Public/Builders`

- SwiftUI に自然な DSL や convenience API

### `Internal`

- 内部 glue code
- adapter
- テスト支援

## 初期段階の現実的な縮約版

最初から上記全部を作る必要はない。初回は以下で十分。

```text
Sources/
  SwGraphUI/
    Core/
      Model/
      Algorithms/
    Runtime/
      State/
    Public/
      API/
      Types/
```

その後、interaction 実装開始時に以下を追加する。

```text
Sources/
  SwGraphUI/
    Core/
      Interaction/
    Runtime/
      Viewport/
      Connection/
      Selection/
```

SwiftUI 本体を入れる段階で以下を追加する。

```text
Sources/
  SwGraphUI/
    UI/
      Container/
      Components/
      Plugins/
```

## 分割ルール

- `Core` は SwiftUI を import しない
- `Platform` は `Core` に依存してよいが、逆依存しない
- `Public` は再 export と facade に留め、実装本体を持ちすぎない
- `UI` は `Core` と `Runtime` を使うが、algorithm の本体を持たない
- `Example` app 固有コードは `Sources/SwGraphUI` に置かない

## 命名ルール

- ディレクトリ名は責務名で切る
- `Utils` の乱立を避ける
- 迷ったら `Model / Algorithms / Interaction / State / UI / Platform / Public` のどれかに寄せる

## 今の時点で避けること

- `Sources/SwGraphUI` 直下にすべて置くこと
- `Helpers`, `Managers`, `Misc` のような曖昧ディレクトリ
- public / internal の境界を混ぜること
- Example app のコードを library target に混ぜること
