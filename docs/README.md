# ドキュメント一覧

このディレクトリは、gomimapの仕様・技術設計・運用方針を管理します。プロジェクト概要と現在の実装状況は[README](../README.md)、参加方法は[CONTRIBUTING](../CONTRIBUTING.md)を参照してください。

## 目的別に読む

| 知りたいこと | 文書 |
| --- | --- |
| 環境構築・起動・ローカル設定 | [開発手順](development.md) |
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
