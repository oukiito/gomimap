# 自治体ごとの版付きデータ

スキーマ1の保存・検証を実装した。現在収録するのは、GPL-3.0-or-laterで作成した[架空の豊島区試験データ](fixtures/toshima-demo-v1.json)のみ。日程・住所・施設・受付条件・取得／確認日時は試験用であり、実際のごみ出しには使用できない。自治体の表・PDF・原文を転載したデータではない。

公開・再配布できる実データは、将来`<municipality-id>/<version>.json`へ追加する。同じ版のファイルを上書きせず、新しい版で変更し、Issue／PRで根拠と差分を確認する。現在は実データを収録していない。自作fixture用の[開発manifest生成・Cloudflare初回配信](../../docs/cloudflare-data.md)は実装し、実公開はまだ行っていない。

構造・判定・検証は[スキーマ1](../../docs/data-schema-v1.md)、Cloudflareと端末の役割は[データ保存・配信設計](../../docs/data-storage.md)を参照する。[出典登録簿](../sources/toshima.json)は原文の取得先・利用条件のメタデータであり、本フォルダーの収集予定と別物。

リポジトリ直下で`python3 scripts/prepare_demo_data.py`を実行すると、同じ試験JSONを`app/assets/generated/`へコピーする。この生成物はGitに含めず、元ファイルは本フォルダーの1か所だけを編集する。スクリプトは指定済みの自作fixtureのみを扱い、原文や実データを自動でアプリへ同梱しない。

`app/`で以下を実行すると、アプリと同じDartの検証処理で確認できる。

```sh
dart run tool/validate_dataset.dart --allow-fixtures ../data/datasets/fixtures/toshima-demo-v1.json
```

実データには`--allow-fixtures`を付けず、対応する出典登録簿を第2引数へ指定する。利用条件が未確認の資料は、JSONへ加工しただけで公開可能になるわけではない。
