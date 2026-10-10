# ドキュメント一覧

このディレクトリは、gomimapの仕様・技術設計・運用方針を管理します。プロジェクト概要と現在の実装状況は[README](../README.md)、参加方法は[CONTRIBUTING](../CONTRIBUTING.md)を参照してください。

## 目的別に読む

| 知りたいこと | 文書 |
| --- | --- |
| 環境構築・起動・ローカル設定 | [開発手順](development.md) |
| 人口／外国籍住民数による導入順位、住宅照合の実装前調査 | [導入順位と調査条件](municipality-rollout.md)、[自治体調査票](municipal-research/TEMPLATE.md)、[豊島区の調査状態](municipal-research/toshima.md) |
| 全国で異なる住所・収集単位、方式別の対応付けと部分確定 | [全国向けの対応設計](national-collection-matching.md) |
| 残作業の難易度、公開単位・判定・破損復旧と実装の開始ゲート | [実装前の契約](implementation-readiness.md) |
| 残る機能の具体的な設計・着手条件・実装順 | [残る機能の設計](remaining-design.md) |
| 朝／前夜の通知、許可・予約・取消・遅延 | [通知の設計](ux-notifications.md) |
| GPS／住所の候補・境界・拒否・自宅の保存 | [位置・住所の設計](ux-location.md) |
| iOSの共有・Timeline・表示容量・追加・タップ | [iOSウィジェット](ux-ios-widget.md) |
| 品物の条件・粗大ごみ・資源回収地図と詳細 | [分別・回収場所](ux-sorting-recycling.md) |
| 地区・版・言語の更新途中の終了とOSへの復旧 | [更新の調整](update-coordination.md) |
| 未完了の受け入れ試験と証拠の区別 | [受け入れ試験](release-test-plan.md) |
| Androidの隔離QA時計・締切／0時の実画面試験 | [QA時計](qa-clock.md) |
| Maestroの導入・MCP起動・試験用IDとFlowの準備状況 | [準備記録](work/2026-10-09-maestro-preparation.md) |
| MaestroによるAndroidの実画面取得・操作・日英ウィジェットの検証結果 | [UI試験の記録](work/2026-10-09-maestro-ui-poc.md) |
| Androidの画面取得・操作・AI連携・自動UI試験の候補 | [自動UI試験の調査](android-ui-test-strategy.md) |
| Android実機の接続・初回準備・試験項目 | [Android実機確認](android-device-testing.md) |
| 初回リリースの画面・通知・ウィジェット・地図 | [プロダクト仕様](product-spec.md) |
| 想定利用者・朝の確認と分別の困りごと | [ペルソナ](personas.md) |
| 全画面・操作・遷移の理由、試作の課題と利用者試験 | [UI・画面遷移の設計](ux-design.md) |
| AIペルソナ想定の実操作・記録方法と限界 | [AI模擬利用評価](ux-ai-evaluation.md) |
| 締切表示・明示的な閉じる・元の品物へ戻る理由 | [締切とナビゲーション](ux-disposal-navigation.md) |
| GPSでの地区設定、地区の常時表示、初回ウィジェット追加の配置・理由 | [初回設定の設計図](ux-initial-setup.md) |
| 自治体・区域・日程・回収拠点の構造 | [データ設計](data-design.md) |
| 実装したJSONのフィールド・判定・公開検証と残る境界 | [データスキーマ1](data-schema-v1.md) |
| GitHub・Cloudflare・端末の保存先と更新の流れ | [データ保存・配信](data-storage.md) |
| 通信待ち・保存失敗・更新後の操作状態をどう扱うか | [更新時のUI設計](ux-data-refresh.md) |
| Androidウィジェットの表示・追加・締切後の切替の理由 | [Androidウィジェット](ux-android-widget.md) |
| 起動画面と起動性能の理由・測定の判断 | [起動時の設計](ux-startup.md) |
| Cloudflareのデプロイ認証・権限・秘密の保存先 | [Cloudflare認証の準備](cloudflare-setup.md) |
| 開発用JSONの初回配信・manifest・公開照合 | [Cloudflareデータ配信](cloudflare-data.md) |
| ライブラリ・配信構成・費用 | [アーキテクチャ](architecture.md) |
| データ取得・検証・更新・障害対応 | [運用設計](operations.md) |
| 開発する作業と完了条件 | [ロードマップ](roadmap.md) |
| Issue・PR・CI・GitHubアカウント | [GitHub運用](github-workflow.md) |
| 開発エージェントが守る利用者優先・設計理由・認証・検証のルール | [AGENTS.md](../AGENTS.md) |
| Android通知の実配送・再起動・Dozeと画面取得 | [隔離配送試験](android-notification-delivery.md) |
| 決定の理由・以前の案からの変更 | [設計上の決定](decisions.md) |
| 自治体・サービスの一次情報 | [調査資料](research.md) |
| 豊島区の取得先・再利用条件・確認状態 | [出典登録簿](sources/toshima.md) |
| ライセンス・依存関係の確認状況 | [ライセンス調査](licenses.md) |
| 過去の実装・確認結果・画面証跡 | [作業記録](work/README.md) |

## 更新のルール

- 仕様は実現する動作、READMEは現在の実装、作業記録は特定の日に実施した作業を示します。計画や方針を実装済みと書きません。
- `decisions.md`の採用方針は、動作検証や契約完了を意味しません。方針変更は理由と日付を残します。
- Issueを作業・議論、PRを変更・確認の記録として使います。ローカル作業IDと実際のIssue番号の対応は[ロードマップ](roadmap.md)で管理します。
- 一つの事実を複数の文書へコピーするより、詳しい文書にリンクします。仕様変更は関連する文書と同じPRで更新します。
- 日本語のMarkdownを基本に、簡潔な見出しとリポジトリ内の相対リンクを使います。個人のPCの絶対パスは汎用手順に入れません。
- 公式データ・料金・利用条件等の調査は、根拠URLと確認日を添えます。未確認の内容は未確認と記載します。
- 作業記録の過去の結果は保存し、現状が変わった場合は後続の記録へ誘導します。完了していないチェックを完了にしません。

GitHubで見つけやすい共通文書はルートの[CONTRIBUTING](../CONTRIBUTING.md)、[SECURITY](../SECURITY.md)、[CODE_OF_CONDUCT](../CODE_OF_CONDUCT.md)、[CHANGELOG](../CHANGELOG.md)に置きます。ライセンス本文は[LICENSE](../LICENSE)、適用範囲は[COPYING](../COPYING.md)です。
