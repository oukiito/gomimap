# Maestroの試験準備

関連：[Issue #42](https://github.com/oukiito/gomimap/issues/42)、[方式](../../docs/android-ui-test-strategy.md)。Flowは準備済みで、画面取得・タップ・配置の成功は未確認。

対象は専用エミュレータ。個人Pixelのデータ消去や権限変更をしない。対象IDを明示し、複数セッションから同時に操作しない。

## 起動準備

リポジトリ直下で公式CLIをローカル配置し、版を確認する。エージェントのコマンドには`rtk proxy`を付ける。

```sh
python3 scripts/install_maestro.py
python3 scripts/maestro_runtime.py --version
python3 scripts/check_maestro_mcp.py
```

CLIは2.11.0、公式archive SHA-256を固定。ホスト側のSDK／JDKは`app/android/local.properties`と`GOMIMAP_ANDROID_SDK`／`GOMIMAP_JAVA_HOME`で指定する。起動時だけ環境変数を設定し、グローバル設定を変更しない。

MCPは`python3 scripts/maestro_runtime.py mcp --no-viewer --working-dir <リポジトリ絶対パス>`をSTDIOサーバーとして登録する。`.codex/config.toml`は個人の絶対パスを含むためGit対象外。接続確認後、現在の提供ツールを使い、承認ポリシーに従う。現在のセッションへの反映は別途確認する。

## 手順

1. 専用エミュレータへ新しいAPKをインストールして起動する。
2. `setup-area.yaml`で日本語・サンプルAを選ぶ。初回のウィジェット画面と実際のOS追加確認をMCPで検査し、表示された確認操作へ進む。未確認の固定座標や確認文言を使わない。
3. 実際にウィジェットが1つ配置されたことを確認して、本体の今日を開く。
4. `app/`から次を実行し、現在時刻の期待値を取得する。日付・締切を跨いだ場合は取り直す。

```sh
flutter test --no-pub tool/maestro_expectation_test.dart
```

5. `.tooling/maestro-results/expectation.json`の`env`を、MCPの`run`へ渡す。`device_id`は専用エミュレータ、`files`は`e2e/maestro/flows/widget-smoke.yaml`を指定する。
6. A01本体、A02ウィジェット、A03復帰後のassertと画像を確認する。Flowが存在すること・要求受理・モデル読み込みの成功だけで合格にしない。

テストは本体とネイティブの実画面を同じ期待値と比較する。FlutterのKeyとは別のSemantics IDを使い、画像は本体カードと自作ウィジェットへ絞る。現在の時計を使うSmokeで、仮の試験時計による締切／0時再現を実装したものではない。

Maestroの結果・画像・ログは`.tooling/`、`build/`、`.maestro/`などGit対象外に置く。クラウド・追加AI解析は有効にしない。秘密や私物画面の画像を公開PRへ送らない。
