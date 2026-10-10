# 作業記録

特定の日付の実装範囲・確認結果・残る課題を保存します。現在の状態は[プロジェクトREADME](../../README.md)と[開発手順](../development.md)で確認してください。下記のIDはGitHub Issue番号ではありません。

| 日付 | 作業 | 記録 | 計画上の関連作業 |
| --- | --- | --- | --- |
| 2026-10-05 | 画面・日程PoC、多言語対応 | [ローカルアプリ開発](G03-local-app.md) | G03 |
| 2026-10-06 | Google Mapsからflutter_mapへの移行 | [地図移行](2026-10-06-map-migration.md) | G03・G09 |
| 2026-10-06 | GitHub初回公開・Issue・CI・保護設定 | [公開記録](2026-10-06-github-bootstrap.md) | [G01／#1](https://github.com/oukiito/gomimap/issues/1) |
| 2026-10-06 | 豊島区の出典・再利用条件・公開検査 | [出典調査](2026-10-06-toshima-sources.md) | [G02／#2](https://github.com/oukiito/gomimap/issues/2) |
| 2026-10-06 | ペルソナ、全画面・遷移の理由、UI変更の運用 | [UI設計記録](2026-10-06-user-first-ux.md) | [#16](https://github.com/oukiito/gomimap/issues/16)、G05〜G09・G12 |
| 2026-10-06 | 地区の常時表示・変更、初回ウィジェット追加の設計 | [地区表示の記録](2026-10-06-district-context.md) | [#18](https://github.com/oukiito/gomimap/issues/18)、G05・G07 |
| 2026-10-06 | 初回の地区確認・保存復旧、AGENTSの共通ルール | [初回設定の記録](2026-10-06-first-run-area.md) | [#20](https://github.com/oukiito/gomimap/issues/20)、G05・G07 |
| 2026-10-07 | 自治体JSON・日程／住所／受入判定、Cloudflareと端末の保存設計 | [データ基盤の記録](2026-10-07-municipal-data.md) | [G04／#4](https://github.com/oukiito/gomimap/issues/4)、G05〜G11 |
| 2026-10-08 | AI模擬操作・締切表示・詳細の閉じる・品物へ戻る | [UI改善の記録](2026-10-08-persona-ui.md) | [#23](https://github.com/oukiito/gomimap/issues/23)、G05・G09・G12 |
| 2026-10-08 | Cloudflareの専用認証・開発JSON初回配信コマンド | [開発データ配信の記録](2026-10-08-cloudflare-data.md) | [#26](https://github.com/oukiito/gomimap/issues/26)、G10・G11 |
| 2026-10-08 | Cloudflare fixtureのアプリ取得・検証・端末保存・復帰 | [端末取得の記録](2026-10-08-dataset-client.md) | [#33](https://github.com/oukiito/gomimap/issues/33)、G05・G11 |
| 2026-10-08 | Android Studio導入・Pixel実機確認の準備 | [Android準備の記録](2026-10-08-android-preparation.md) | [#3](https://github.com/oukiito/gomimap/issues/3) |
| 2026-10-08 | Android SDK準備・初回デバッグAPKのビルド成功 | [Androidビルドの記録](2026-10-08-android-build.md) | [#3](https://github.com/oukiito/gomimap/issues/3) |
| 2026-10-08 | Pixelで起動・地区保存、更新失敗の切り分け | [Pixel実機の記録](2026-10-08-pixel-runtime.md) | [#3](https://github.com/oukiito/gomimap/issues/3) |
| 2026-10-08 | Androidウィジェット・2×2・締切後の次回表示・初回追加 | [ウィジェット記録](2026-10-08-android-widget.md) | [#7](https://github.com/oukiito/gomimap/issues/7)、G05 |
| 2026-10-09 | Maestroローカル導入・MCP起動・Semantics ID・Flow準備 | [Maestro準備](2026-10-09-maestro-preparation.md) | [#42](https://github.com/oukiito/gomimap/issues/42)、G03・G07 |
| 2026-10-09 | Maestroの実画面取得・OS追加・日英の比較／復帰、締切の文字切れと言語更新を修正 | [Maestro UI試験](2026-10-09-maestro-ui-poc.md) | [#42](https://github.com/oukiito/gomimap/issues/42)、[#7](https://github.com/oukiito/gomimap/issues/7) |
| 2026-10-09 | 通知・位置・iOS・分別地図・更新復旧・運用の設計と受け入れ試験 | [残る設計の記録](2026-10-09-remaining-design.md) | [#45](https://github.com/oukiito/gomimap/issues/45)、G03・G05〜G12 |
| 2026-10-09 | Android隔離QA時計・締切／0時／複数締切等9ケースの実画面確認 | [QA時計の記録](2026-10-09-android-clock-qa.md) | [#47](https://github.com/oukiito/gomimap/issues/47)、G03・G05・G07 |
| 2026-10-09 | Android通知の初回・設定・許可・予約／取消・QAのOS通知と対象日タップ | [通知の記録](2026-10-09-android-notifications.md) | [#49](https://github.com/oukiito/gomimap/issues/49)、G05・G06 |
| 2026-10-09 | Android実予約からの配送、再起動・Doze、期限／取消・QA計測と新しいMCP接続 | [実配送の記録](2026-10-09-android-notification-delivery.md) | [#51](https://github.com/oukiito/gomimap/issues/51)、G06 |
| 2026-10-09 | GSIタイル接続・地図のpan／タブ復帰保持・失敗と一覧 | [地図接続の記録](2026-10-09-gsi-map.md) | [#54](https://github.com/oukiito/gomimap/issues/54)、G09 |
| 2026-10-10 | 住所条件→候補→既存確認、取消・回答非保存とミニマル方針 | [住所選択の記録](2026-10-10-address-selection.md) | [#56](https://github.com/oukiito/gomimap/issues/56)、G05 |
| 2026-10-10 | クリア済みCSVの実取得・hash／304・候補・週次workflowと外部health | [CSV監視の記録](2026-10-10-cleared-catalog-monitor.md) | [#58](https://github.com/oukiito/gomimap/issues/58)、G10 |
| 2026-10-10 | 地区・言語・日程版・通知設定の直列更新、journal復旧・失敗再試行 | [更新復旧の記録](2026-10-10-update-coordination.md) | [#60](https://github.com/oukiito/gomimap/issues/60)、G11 |
| 2026-10-10 | 開発履歴・未完了・サービス観測・再開条件とAGENTS更新 | [開発の保存記録](2026-10-10-development-checkpoint.md) | [#63](https://github.com/oukiito/gomimap/issues/63)、[#53](https://github.com/oukiito/gomimap/issues/53) |
| 2026-10-10 | 難易度・公開／判定／復旧／運用の追加契約と実装開始ゲート | [着手設計の記録](2026-10-10-implementation-readiness.md) | [#65](https://github.com/oukiito/gomimap/issues/65)、[#53](https://github.com/oukiito/gomimap/issues/53) |
| 2026-10-10 | 設計D2に基づく分別の優先順位・不明・矛盾の判定核 | [分別判定の記録](2026-10-10-sorting-decision.md) | [#67](https://github.com/oukiito/gomimap/issues/67)、G08 |
| 2026-10-10 | 全国の住所・品目別区域・地域回収・夜間への対応設計を見直し | [全国対応の記録](2026-10-10-national-collection-matching.md) | [#69](https://github.com/oukiito/gomimap/issues/69)、G04・G05 |
| 2026-10-10 | 人口／外国籍住民数の順位方式、MR詳細調査と豊島区の未完了台帳 | [導入・調査条件の記録](2026-10-10-rollout-research-gate.md) | [#71](https://github.com/oukiito/gomimap/issues/71)、G04・G05 |
| 2026-10-10 | 総人口順位の全国一覧、上位自治体と住宅照合の瑕疵点検 | [全国調査の記録](2026-10-10-national-research.md) | [#73](https://github.com/oukiito/gomimap/issues/73)、G04・G05 |

画面証跡は`screenshots/`にあります。Web、ネイティブ、エミュレータ、実機、本人観察を各記録で区別します。架空データの画像を実データの正確性の証拠として扱いません。リリースの変更点は[CHANGELOG](../../CHANGELOG.md)へまとめます。
