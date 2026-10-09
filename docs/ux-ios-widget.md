# iOSホーム画面ウィジェットの設計

2026-10-09。#7、UX02・07・10、S14、B13〜20。iOSのビルド・ウィジェット・配置試験は未実施。Androidの成功をiOSの成功として扱わない。[共通の切替](remaining-design.md#日付と主表示の共通契約)を使う。

## 共有とTimeline

SwiftUI／WidgetKitの1種類のホーム画面ウィジェットと、SwiftのOSブリッジを第一案とする。Androidは既存のKotlin実装を継続し、home_widgetを導入必須にしない。App Groupのコンテナへ書き込むための署名・entitlement・端末条件をiOS PoCで確認する。使えない開発署名を、実装が完了した扱いにしない。

本体は検証済みの共通Calendarから35日分のschema2投影を作る。iOS用の新しい共有envelopeは形式版、反映世代、自治体・地区・データ版・選択言語、投影payloadを一体で持つ。候補をflush／同一コンテナ内renameし、WidgetKitは途中ファイルを読まない。Androidの現在のschema2ファイルを新形式として黙って読み替えず、橋渡しはプラットフォーム別に行う。世代・地区・版・言語・期間が一致しない、未知形式、破損なら確認必要を表示する。

WidgetKitは投影済みの時間帯を選ぶだけで、自治体の収集規則をSwiftに再実装しない。現在時刻、各締切、日本0時に対応する表示entryを生成する。隣接する同じ表示はまとめ、最大256entryをアプリ側の初期上限とする。上限に達する場合は最後にカバー終了時刻の確認必要entryを追加し、カバー外を確定予定として延長しない。投影終了の確認必要entryも用意する。

Timelineの再要求はカバー終了前を希望し、地区・版・言語変更では共有保存後にreloadTimelinesを要求する。どちらもOSの実際の描画到達を保証しない。追加のネットワーク取得・位置取得・LLM呼出はWidget Extensionで行わない。更新が遅れた古い表示でも、絶対日付で対象日を照合できるようにする。[AppleのTimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider)、[更新](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)。

## UI・操作・理由

| ID | 要素・操作 | 利用場面・理由 | 戻る・保持・失敗・確認 |
| --- | --- | --- | --- |
| IW01 | 今日／明日／次回＋絶対日付、地区、全区分と締切 | アプリを開かず何をいつ出すか確認 | 共通投影を使用。今日不明は飛ばさず確認表示。fixtureはサンプルと明示 |
| IW02 | 小型を第一候補に、MediumもPoC | ホーム画面の場所を取り過ぎず、複数区分も読める必要がある | 小型の全言語・全区分・文字拡大で情報が読めればSmallを提供。満たせなければ初版はMediumのみ。Mediumも不合格なら配置可能な完成品として提供せずレイアウトを修正 |
| IW03 | 共通締切は1行、異なる締切は区分別 | 重複を減らしつつ出し忘れを防ぐ | 文字を極端に縮める／種類を隠す／未確認の略称を使うことで合格にしない。次々回は主情報が読める場合だけ追加 |
| IW04 | ウィジェット全体のタップで対象日のS05へ | 小さい個別ボタンを探さず詳しい出し方を読める | URLは対象日・自治体・区域・版の意味IDだけ。現在の地区と照合し、古い日を今日と表示しない。S05から今日へ戻れる |
| IW05 | 初回のプレビュー・追加方法を見る／スキップ | ウィジェットに不慣れでも内容と追加方法が分かる | OSの手順案内へ。自動配置を約束せず、回答後は再提案しない。追加未確認でも本体を使える |
| IW06 | 設定から追加手順と配置状況の再確認 | 初回スキップ・削除後にも追加したい | 対象kindの配置一覧が取得できれば表示。失敗は追加状況を確認できません。手順表示・アプリへの復帰だけで追加済みにしない |
| IW07 | VoiceOver・Dynamic Type・色に依存しない表示 | 小さな日常表示でも読み方を選べる | 日付→地区→全区分→締切→状態の順。通常色・OSの色調変更・読み上げ・文字拡大で実画面確認 |

サイズはOSが決めるfamilyで、Androidの2×2の寸法をiOSへコピーしない。[AppleのWidget設計](https://developer.apple.com/design/human-interface-guidelines/widgets)を踏まえたIW02は製品の選択基準で、Smallの合格・提供を確認したものではない。1種類のkindでfamilyを提供し、地区をウィジェット側で入力し直させない。

配置確認には最低対応OSで使えるWidgetCenterの構成取得APIを検証する。[構成の取得](https://developer.apple.com/documentation/widgetkit/widgetcenter/currentconfigurations%28%29)。取得結果はその時点の対象kindの確認で、恒久的な削除通知の保証ではない。追加手順は[Apple公式](https://support.apple.com/ja-jp/118610)に合わせ、OSの言語・版により異なる表記を実機で確認する。

## 受け入れ条件

共有・旧形式移行・破損・別地区・期限・言語をネイティブ試験し、同じfixture時計の本体とTimeline entryを比較する。Simulatorでは追加・削除・S05へのタップ・通常／拡大／各言語を実際の画面で確認する。iPhoneではオフライン、長期未起動、日付／締切、OS更新遅延を別に確認する。MaestroのiOS Simulator対応をiPhone実機の自動操作対応と混同しない。[V07](release-test-plan.md)。

配置要求・Timeline生成・reload要求、実際のホーム画面描画は別の記録を残す。ストア登録は後回しで、まず開発用ビルド・署名・共有が成立する範囲を確認する。
