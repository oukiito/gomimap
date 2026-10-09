# 開発履歴と再開時の確認点

2026-10-10時点。[Issue #63](https://github.com/oukiito/gomimap/issues/63)。実装の基準コミットは`5237c7c`（PR #61取り込み後）。以後の変更はGit履歴と[作業記録一覧](README.md)を確認する。開発版であり、実際のごみ出しに使える公開アプリではない。

## 開発の経過

| 時期 | 実装・決定・確認 | 記録 |
| --- | --- | --- |
| 10/5〜6 | Flutterの画面PoC、10言語、GPL-3.0-or-later、GitHub Issue／PR／CI、ペルソナとUI理由。Google Mapsからflutter_mapへ移行 | [画面PoC](G03-local-app.md)、[公開基盤](2026-10-06-github-bootstrap.md)、[UI方針](2026-10-06-user-first-ux.md)、[地図移行](2026-10-06-map-migration.md) |
| 10/7〜8 | 自治体別JSON、区域・日程・受入条件の検査。架空データのCloudflare配信・HTTPS照合・端末保存。初回地区確認と状態保持 | [データ基盤](2026-10-07-municipal-data.md)、[配信](2026-10-08-cloudflare-data.md)、[端末取得](2026-10-08-dataset-client.md) |
| 10/8 | Android SDK導入、Pixelで起動・地区保存・再起動保持、本人のオフライン確認、profile起動測定。2×2ウィジェットと締切後の次回表示 | [実機記録](2026-10-08-pixel-runtime.md)、[ウィジェット](2026-10-08-android-widget.md) |
| 10/9 | Maestroの画面取得・操作、隔離QA時計で締切／0時等9ケース、任意通知・予約／取消・対象日へのタップ。専用エミュレータで実予約配送・再起動・Doze試験 | [GUI試験](2026-10-09-maestro-ui-poc.md)、[時計](2026-10-09-android-clock-qa.md)、[通知](2026-10-09-android-notifications.md)、[配送](2026-10-09-android-notification-delivery.md) |
| 10/9〜10 | 国土地理院の地図接続・位置保持、住所条件→地区候補→確認／取消のフォーム、ミニマルなUI方針 | [地図／PR #55](2026-10-09-gsi-map.md)、[住所／PR #57](2026-10-10-address-selection.md) |
| 10/10 | 権利確認済みCSV2件の週次監視・メタデータ候補。GitHub初回手動実行は2件unchanged・失敗0・対象外12件、外部health正常 | [監視／PR #59・#62](2026-10-10-cleared-catalog-monitor.md)、[実行結果](https://github.com/oukiito/gomimap/actions/runs/37972368307) |
| 10/10 | 地区・言語・日程版・通知希望を直列更新し、未完了journalと確定済み状態から通知／ウィジェットを再照合。失敗理由と再試行は設定へ配置 | [復旧／PR #61](2026-10-10-update-coordination.md) |

全てのUI・UXの理由は[UI設計](../ux-design.md)と各詳細設計へ保存する。通知は[NT](../ux-notifications.md)、ウィジェットは[W](../ux-android-widget.md)、更新復旧は[UP](../update-coordination.md)。初回設定ではGPSを候補取得に限定し、実地区確認前に日程を切り替えない方針。

## 最新の検証と追加記録

PR #61の最新head `8a9e125`は必須CI appが成功し、mainへ取り込み済み。ローカル全体258件PASS・live取得1件skipの後、Webでネイティブ通知がない場合の復旧テストを追加し、接続6件PASS。整形・解析・Web・Android profileビルドは成功。CI成功をPixel／iOSの検証と同一にしない。

専用API37エミュレータで、地区・言語の終了／再起動保持、旧A／新Bのstopped記録からBを保持してpendingを解消することを確認。これは試験記録の注入であり、実際の保存コードの特定の瞬間に強制終了した試験ではない。

さらに最新の隔離QAへ破損journalを注入し、設定の失敗理由と再試行をMaestro MCPで確認（7操作成功）。[失敗画面](screenshots/2026-10-10-update-failure-settings.png)は架空地区・専用エミュレータのみ。試験前のjournalをバイト一致で復元し、再起動後のエラー非表示・地区Aへの復帰を確認（7操作成功）。地区A・日本語・実時計・通知希望OFFを保持。個人端末、OS時計、ネットワーク設定を変更していない。破損時の利用者向け自動復旧を実装した証拠ではない。[追加試験のPRコメント](https://github.com/oukiito/gomimap/pull/61#issuecomment-6087081647)。

## 開発用サービスの確認結果

10/10にMacのプロセスとTCP待受を確認した時点の情報。起動状態・PID・一時ポートは固定の構成仕様ではない。

| プロセス | 用途・確認した状態 |
| --- | --- |
| Android SDK公式エミュレータ | 専用API37 AVDをheadlessで稼働。ADB一覧ではエミュレータ1台、Pixel接続なし |
| ADB server | APK導入・端末との通信。localhost:5037で待受 |
| Maestro MCP | ごみまっぷの作業ディレクトリに2つの接続プロセス。stdioで接続、no-viewer。2本必要と決めた構成ではなく、終了・所有を確認する対象 |
| Gradle daemon | Androidビルドのため常駐。Android Studio付属JDKを使用 |
| Kotlin compile daemon | Kotlinのコンパイルを再利用するため常駐 |
| netsimd | エミュレータが起動する通信シミュレーション用の補助プロセス |

以前のWebプレビュー8768は確認時点でTCP待受がなかった。Flutter実行サーバー・このプロジェクト用のローカルAPI／DBサーバーも確認できなかった。CodexやOSの補助サービス、別アプリのプロセスを、このプロジェクトが起動したものと扱わない。Cloudflareのfixture配信とGitHub ActionsはMac外で動作し、ローカルの常設監視ではない。

## 残作業と再開順

[親Issue #53](https://github.com/oukiito/gomimap/issues/53)の1〜6は全体として未完了。小さな子Issueを閉じたことを親の完了に置き換えない。

| 項目 | 残る条件・作業 |
| --- | --- |
| 1 豊島区の実データ | HTML／PDF12件の再利用・保管・送信条件を確認。CSV施設558件を資源回収拠点数と扱わない。公式資料の閲覧と再配布許可は別 |
| 2 初回地区設定 | 実地区プロファイル・位置候補ブリッジ・区域照合。拒否／境界／未対応と確認保存。GPSを架空地区へ割り当てない |
| 3 分別・回収地図 | 版付き分別／粗大ごみルール、品目ごとの受入条件とサービス判定を画面へ接続。拠点は現在架空 |
| 4 更新復旧 | 破損／食い違いの確認付き復旧UI、実中断点・電源断・実地区／製品データでの照合。複数ファイルとOSの原子性は未保証 |
| 5 運用 | 初回schedule到達・実障害通知、候補PR・承認後配信、常設独立監視と通知先、月次LLMの契約・予算・実行。healthコマンドの成功だけで常設監視と呼ばない |
| 6 Android検証 | Pixelの長期・省電力・強制停止、アプリ非起動中のウィジェット実更新。手動更新／試験時計／OSの自動更新を区別 |

問い合わせ文案は[再利用条件の問い合わせ](../sources/toshima-reuse-inquiry.md)。送信方法・明示的な送信許可は未回答で、送信済みとは記録しない。実機試験はUSB再接続を確認してから行う。GitHub Actions実行権限の変更は確認済みで、初回手動実行は完了。iOSはXcode本体・両OS実機の準備、ストア登録・公開と写真AIは後続。

次回はREADME・本記録・親Issueと該当子Issueを読み、現在のチェックアウト、秘密を除いた認証先、実際の端末／サービスの状態を再確認する。独立して進められる実装を進め、外部依存の未回答を承認と解釈しない。
