# ライセンスとライブラリ選定

確認日：2026-10-06、データ取得・保存の追加確認は2026-10-08。これは開発時点の依存関係調査で、完成したiOS／Androidバイナリの配布承認ではない。

## プロジェクトのライセンス

利用者の指定によりMIT案から **GPL-3.0-or-later** に変更。GPLの版は未指定だったため、GPL第3版またはそれ以降を採用した。[LICENSE](../LICENSE)にGNU公式の原文、[COPYING.md](../COPYING.md)に適用宣言と対象範囲を置いた。独自のSDKリンク例外や二重ライセンスは追加していない。

GPLは商用利用を禁止しない。配布する改変版等にはGPLの条件を守り、対象となるソースとビルドに必要な情報を提供する。第三者コードの著作権表示・許諾文・必要なNOTICEを保持する。自治体資料や地図をGPLへ変更する権限を与えるものではない。根拠は[GPLv3原文](https://www.gnu.org/licenses/gpl-3.0.html)の第4〜6・10・14節。原文はGNUのテキスト配布URLから取得した。

## すでに導入したもの

実際に解決された`app/pubspec.lock`とローカル配布物のLICENSE本文を確認した。pubspecの許容範囲ではなく解決済みバージョンを記載。

| 用途 | ライブラリ／版 | ライセンス本文 | 判断 |
| --- | --- | --- | --- |
| アプリ本体 | Flutter 3.47.6 / Dart 3.13.5 | FlutterはBSD-3-Clause。Dart・エンジン内第三者コードは別通知も保持 | 継続。SDK全体を単一BSDとして扱わない |
| 多言語 | flutter_localizations（SDK）、intl 0.20.3 | BSD-3-Clause | 継続 |
| 地域・言語の保存 | shared_preferences 2.5.5 | BSD-3-Clause | 継続。大量の自治体データはDBへ |
| 公式サイト・外部リンク | url_launcher 6.3.3 | BSD-3-Clause | 継続 |
| 地図描画・座標 | flutter_map 8.3.2 / latlong2 0.9.1 | BSD-3-Clause / Apache-2.0 | Google Mapsの依存を除去。配信元は未設定 |
| データ取得・checksum・保存先 | http 1.6.0 / crypto 3.0.7 / path_provider 2.1.6 | 全てBSD-3-Clause | 既存の推移依存を同じ版で直接利用。通知を保持 |
| アイコン | cupertino_icons 1.0.9 | MIT | テンプレート依存。現在主にMaterial Iconsを使用 |
| 開発用解析・テスト | flutter_lints 6.0.0、flutter_test（SDK） | BSD-3-Clause | 開発用。完成バイナリへの包含とは区別 |

直接・推移・開発用・別OS用を含む**86パッケージ**のライセンス本文とSHA-256を保存：[一覧](../third_party/README.md)、[機械可読の記録](../third_party/dart-packages.json)。Flutter SDK内で個別LICENSEを持たないパッケージはリポジトリのLICENSEを参照している。

本文の一次分類はBSD-3-Clause 72、Apache-2.0 4、MIT 9、エンジンの集約通知1。`sky_engine/LICENSE`は多数の第三者通知を含むため、全体をBSDと判定していない。各ファイル内の個別通知とリリース成果物への包含は別途照合する。削除したGoogle Maps系の通知は現行一覧から除去した。

BSD-3-Clause・MITは表示等の条件を保持してGPLと組み合わせる。Apache-2.0もGPLv3との組合せが可能で、GPLv2-onlyとは異なる。[Apache Software Foundationの説明](https://www.apache.org/licenses/GPL-compatibility.html)。この判断をプロプライエタリSDKや地図サービスへ拡張しない。

## データ取得・保存の追加確認

2026-10-08の取得・保存実装では上記3パッケージを直接依存へ移した。lockfileの版・推移的パッケージ集合は変わらず86件。再生成したライセンス本文・版・本文SHA-256も同じで、lockfileのSHA-256だけを更新した。一次資料：[http](https://pub.dev/packages/http)、[crypto](https://pub.dev/packages/crypto)、[path_provider](https://pub.dev/packages/path_provider)、同じ解決版の[保存した原文](../third_party/README.md)。利用時の追加ライブラリ料金はなく、Cloudflareの通信・配信費用は[別途のサービス条件](data-storage.md)に従う。

Flutterラッパーだけで判断せず、解決済み`path_provider_android 2.3.1`と`path_provider_foundation 2.6.0`の実装も確認した。Androidは既存の`jni`／`jni_flutter`経由でOSのContext.filesDirを、iOSは既存の`ffi`／`objective_c`経由でFoundationのApplication Supportを使う。これらのパッケージ・関連する既存のネイティブビルドhookの通知も現行一覧に含まれ、追加の商用SDK・地図契約を導入していない。`http`の標準クライアントはDart HttpClient／ブラウザーfetch、`crypto`はDartのSHA-256処理。OS API・SDK・エンジン全体をBSDへ変更する意味ではなく、完成バイナリでのネイティブ成果物・必要通知・両OSビルドの監査は後続。

収集データをネイティブの`shared_preferences`へ大量保存しない。同プラグインの[公式注意](https://pub.dev/packages/shared_preferences)は重要データの書込耐久性を保証していないため、JSONは専用ファイルを使い、Webの利用は消失しうる確認用キャッシュに限定した。

## SDK付属フォント・アイコン

パッケージ一覧とは別に、使用中のFlutter SDKの`bin/cache/artifacts/material_fonts`に同梱された原文を[保存](../third_party/fonts/README.md)した。

| 素材 | 同梱されたライセンス |
| --- | --- |
| Material Icons | CC-BY-4.0 |
| Roboto / Roboto Condensed | Apache-2.0 |

Material Iconsをコードと一緒にGPLへ再ライセンスしない。CC-BY-4.0第3節に従い、提供された権利者表示・ライセンス参照を維持し、変更がある場合はその旨も表示する。リリース時のアイコンのサブセット化も含め、実際の成果物とアプリ内表示を確認する。Roboto Condensedの保存はSDKに含まれる素材の記録であり、アプリへの同梱を意味しない。

## 今後の具体的な候補

2026-10-08の開発用Cloudflare配信は、Python標準ライブラリと既存Dart検証処理を使う自作コード。Cloudflare SDK、Wrangler、npmパッケージやネイティブSDKを新たに追加していない。公開するfixture・配信スクリプト・Workerの自作部分はGPL-3.0-or-later。Cloudflareサービスの利用条件・料金はコードのライセンスとは別に[配信手順](cloudflare-data.md)へ記録する。

以下は未導入。pub.devの該当バージョン配布アーカイブからLICENSEを取得して[候補の通知](../third_party/candidates/)へ保存した。表のライセンスは当該パッケージ自身のもの。候補の推移依存を現行アプリへ解決したわけではない。

| 用途 | 第一候補／調査版 | ライセンス | 採用方針 |
| --- | --- | --- | --- |
| ローカル通知 | flutter_local_notifications 22.3.1 | BSD-3-Clause | 朝の通知予約に検証。OS制限とネイティブ依存も確認 |
| 通知時刻 | timezone 0.11.1 | BSD-2-Clause | 日本時間の予約。付属タイムゾーンデータも確認 |
| ウィジェット連携 | home_widget 0.10.0 | BSD-3-Clause | 本体とデータ共有。SwiftUI／Android側の画面は別実装 |
| 端末DB | drift 2.35.1 | MIT | 収集予定・品目・拠点のオフライン保存。sqlite3等の実配布構成は追加監査 |
| 状態管理 | flutter_riverpod 3.4.3 | MIT | 非同期データ更新の段階で検証。現在はFlutter標準のState |
| 位置情報 | geolocator 14.1.1 | MIT | **保留**。ラッパーのMITだけで採用を確定しない |

一次情報：[通知](https://pub.dev/packages/flutter_local_notifications/license)、[home_widget](https://pub.dev/packages/home_widget/license)、[drift](https://pub.dev/packages/drift/license)、[Riverpod](https://pub.dev/packages/flutter_riverpod/license)、[flutter_map](https://pub.dev/packages/flutter_map/license)、[geolocator](https://pub.dev/packages/geolocator/license)。バージョンを更新したら再確認する。

## GPL化で見直す点

### Google Mapsと位置情報

Google MapsのFlutterラッパーがBSDでも、リンク先のGoogle Maps SDKをGPLで再配布できるという意味ではない。SDKにはGoogleとの契約・利用規約が適用される。[iOS SDK公式ポリシー](https://developers.google.com/maps/documentation/ios-sdk/policies)、[サービス規約](https://cloud.google.com/maps-platform/terms)。GPLが求める配布・対応ソース等の条件との整合が未確認のため、現行Google SDKを含むバイナリを「GPL適合済み」としない。

また候補`geolocator_android` 5.1.1+1の配布アーカイブの`android/build.gradle`で、`com.google.android.gms:play-services-location:21.2.0`への依存を確認した。ランタイムでLocationManagerを選ぶだけでは依存バイナリが消えるとは限らない。OS標準の位置APIへ直接つなぐ構成などと比較し、非自由SDKの包含を避ける案を優先する。

2026-10-06にGoogle MapsのDart依存、iOS初期化とAPIキー設定、AndroidのAPIキー設定を削除した。`flutter_map`へ置換済み。現行lockfileにGoogle Maps依存がないことを確認。ネイティブ成果物は未ビルドであり、完成バイナリの監査は別途必要。タイル配信元は未設定で、地図サービスの利用条件は本体GPLと別に確認する。

### iOS配布

GPL採用だけでApp Store公開が確約されるわけではない。GPL第10節の追加制限禁止と、ストアの契約・DRM・EULA・対応ソース提供方法を公開前に確認する。[Apple標準EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)には譲渡・再配布等の制限とOSSに関する例外記載があるため、実際の配布条件全体で判断する。一律に不可能とも、自動的に問題なしとも断定しない。必要なら配布条件を扱う専門家へ確認する。開発自体は継続できる。

## 更新時の作業

1. `flutter pub get`後、ルートで`python3 scripts/license_inventory.py`を実行。本文・ハッシュ・lockfileハッシュの差分をPRで確認する。分類処理は一次判定であり、人の確認の代替ではない。
2. 実機ビルド環境の準備後、Gradle／SPM／CocoaPodsの解決済み依存も固定して監査。今回そのグラフは未生成。
3. リリース成果物のフォント・アイコン・エンジン・NOTICEを照合し、アプリ内ライセンス表示と配布物へ含める。今回の本文保存だけで表示義務を完了扱いにしない。
4. GPL対象の対応ソース、ビルド手順、変更履歴、必要なインストール情報の提供方法を確認する。第三者素材の権利者表示は維持し、自治体データの出典・条件は別記する。
