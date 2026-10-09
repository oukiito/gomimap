# 難易度評価と実装前の追加契約

2026-10-10。[Issue #65](https://github.com/oukiito/gomimap/issues/65)、親#53。利用者の設計先行の依頼に従い、コード・既存の設計・最新のAndroid／GitHub／Cloudflare一次資料を照合した。アプリコード、依存、実資料の許可、外部jobの変更はない。

技術的に最も難しい更新運用とOS復旧、外部依存が最も大きい実データを区別。[追加契約 D1〜6](../implementation-readiness.md)へ自治体bundle v2、三値の分類／優先順位、地図の適合と営業、GeoPack／要求ID、製品DeviceStateと破損復旧、審査／公開／独立監視を記録。UI理由RD01〜05、試験と開始ゲートG1〜7を追加した。

既存設計のiOS先行の順序、接続前を前提にした地図の記述、取得timeoutの15／20秒の差を訂正。GSI接続済み・Android先行・現行CSVと同じ20秒へ整合。未解決の実資料・幾何PoC／依存・監視通知先・LLM契約・電源断保存PoCは着手条件として残す。

新規読者レビューで、端末の確定点の二重解釈、pendingの世代／phase、専用経路／準備IDとcm精度、job別成功／意図停止の4点を指摘された。DeviceStateの単一確定・世代付きprevious／targetの表、登録簿・丸めない入力、段階別receiptと監視自身の生存を追記して修正後の再レビューPASS。schema1にないchannelの要求も解消し、状態名と既存のOP06を整合した。文書リンク・公開情報・diffの検査成功。必須CIの最終結果は対応PRを参照する。AI読者レビューは人の原文照合や製品合格の代わりではない。次の実装はG2のfixture分別判定からとし、設計保存を#53の完了と扱わない。
