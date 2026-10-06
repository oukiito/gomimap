# 豊島区の出典・再利用条件

確認日：2026-10-06（Asia/Tokyo）。関連：[Issue #2](https://github.com/oukiito/gomimap/issues/2)。機械可読の登録簿は[data/sources/toshima.json](../../data/sources/toshima.json)。これは取得先・確認状態のメタデータであり、利用者に配信する収集予定や回収拠点データではありません。

## 対象資料

以下のリンク先は豊島区公式サイトです。更新日はページ本文の表記を使い、取得日・HTTP Last-Modified・制度の適用日とは分けて記録しています。更新日が確認できないものは未記載のまま保持します。

| 登録ID | 公式資料 | 主な用途・確認箇所 | 本文の更新日 |
| --- | --- | --- | --- |
| toshima-weekdays | [収集曜日PDF](https://www.city.toshima.lg.jp/documents/1056/syuusyuyoubiitiran.pdf) | 一般区域・繁華街区域の2表、番地・通り沿い条件、月内曜日、締切。1ページを画像で確認 | 未記載 |
| toshima-resources | [資源](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/009426.html) | 分別、曜日PDFへのリンク、締切、持込品目へのリンク | 2026-07-11 |
| toshima-household | [通常ごみ](https://www.city.toshima.lg.jp/151/kurashi/gomi/shigen/009329.html) | 燃やすごみ・金属等の区分、除外品、締切 | 2026-05-13 |
| toshima-year-end | [年末年始](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2211020850.html) | 日付例外。本文は2025–2026年向けで、次年度の根拠にはしない | 2025-12-26 |
| toshima-rechargeable | [小型充電式電池](https://www.city.toshima.lg.jp/151/2601221355.html) | 収集経路、取り外せない電池、膨張品の別扱い、持参条件 | 2026-05-13 |
| toshima-batteries | [乾電池・ボタン電池](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2509251342.html) | 電池の種類、回収施設、工事・休止、店舗 | 2026-09-02 |
| toshima-small-electronics | [小型家電](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/034106.html) | 投入口、寸法、電池、家庭由来、回収施設 | 2026-08-10 |
| toshima-fluorescent | [蛍光灯](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/026267.html) | 破損品・LED等の除外、開館時間、休止施設 | 2026-08-10 |
| toshima-bulky | [粗大ごみ](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/009383.html) | 寸法、家電等の除外、事前申込への導線 | 2026-09-29 |
| toshima-notices | [お知らせ一覧](https://www.city.toshima.lg.jp/kurashi/gomi/katei/oshirase/index.html) | 臨時情報の発見。一覧だけで個別の日程を確定しない | 表記なし |
| toshima-weather | [台風・大雪等](https://www.city.toshima.lg.jp/151/2010101045.html) | 中止・時刻変更の基準と当日の案内方法 | 2026-06-03 |
| toshima-facilities | [公共施設一覧CSV](https://www.city.toshima.lg.jp/documents/11459/r5_public_facility.csv) | 住所・座標・開館情報の候補。回収受付の根拠とは分離 | 未確認 |
| toshima-open-data-list | [オープンデータ一覧CSV](https://www.city.toshima.lg.jp/documents/11459/r5_open_data_list.csv) | 対象ファイル・ライセンス等の発見 | 未確認 |
| toshima-calendar-link | [カレンダー案内](https://www.city.toshima.lg.jp/150/kurashi/gomi/shigen/2303021832.html) | さんあ〜るWeb版への公式導線。取得APIとして扱わない | 2025-01-06 |

収集曜日PDFは、現在の資源案内がリンクする`/documents/1056/syuusyuyoubiitiran.pdf`を採用候補にしました。以前の調査にある`/documents/15278/youbiitiran.pdf`は別の4ページ資料で、同じ版として扱いません。現在のPDFも制度の有効期間は別途確認が必要です。

## 保管と再配布の区別

| 資料の範囲 | 原資料の継続保管 | 加工したデータの再配布 | 判断の根拠 |
| --- | --- | --- | --- |
| 登録した公共施設CSV・オープンデータ一覧CSV | 表示等の条件を守って可能と記録 | 同じ条件で可能と記録 | [豊島区オープンデータ](https://www.city.toshima.lg.jp/020/kuse/electronic/open-data/1511041608.html)で対象リンクとCC BY 2.1 JPを確認 |
| ごみ案内HTML・PDF | 個別条件を要確認 | 個別条件を要確認 | [一般サイト方針](https://www.city.toshima.lg.jp/012/kuse/koho/homepage/sitepolicy.html)では文書・画像等の無断複製・転用に制限がある。個別許諾は未取得 |
| 原資料のURL・確認日・自作の調査メモ | 登録簿に記録 | 登録簿として公開 | 原文本文・画像・表の全文コピーは含めない |

CC BY 2.1 JPは指定データだけに適用されます。同じ区のWebページ・添付PDF全体へ広げたり、GPLへ変更したりしません。CSV由来のデータには豊島区の出典と元のライセンスを表示し、加工内容も記録します。施設CSVの558行は回収拠点数ではありません。現在の回収場所・受付条件・休止を確認してから施設と対応付けます。

この整理は確認できた利用条件に基づく開発上の評価です。事実の独自整理が直ちに禁止されると断定しているわけではありません。原文の保存、機械取得、構造化・翻訳、アプリ同梱・配信を分けて判断するため、未確認部分は許諾済みにしません。[問い合わせ文案](toshima-reuse-inquiry.md)は未送信です。回答の確認と登録簿への反映は[Issue #14](https://github.com/oukiito/gomimap/issues/14)で追跡します。

## 検証と公開への接続

リポジトリ直下から実行します。Python標準ライブラリだけを使用します。

```sh
python3 scripts/validate_sources.py
python3 -m unittest discover -s scripts/tests -v
```

登録簿には要確認の資料も記録できます。一方、配布元の利用条件を確認する場合は、使う資料を明示します。

```sh
# 対象データと利用条件が確認できたCSV：利用条件の検査を通過
python3 scripts/validate_sources.py --publish-source toshima-facilities

# 収集曜日PDF：現状は再配布条件が未確認なので終了コード1
python3 scripts/validate_sources.py --publish-source toshima-weekdays
```

検査は、利用条件の対象URL、根拠、ライセンス、出典表示、保管／再配布の別々の判断、未登録ID、過年度資料を確認し、原文保存用などの未定義フィールドを拒否します。調査メモ欄へ長い原文が貼られていないことはPRの公開対象点検で確認します。**検査成功は、日程・座標・受付条件の正確性や人による公開承認を意味しません。** 登録簿と回帰テストは既存の必須CI `app`へ追加しました。製品データ・取得・配信への接続はG04／G10で実装するため、本番配信が稼働しているとは扱いません。

## 後続の実装条件

- G04：区域の番地・通り条件、月内曜日、締切、有効期間、根拠IDを持つ。2026–2027年の年末年始は未確認状態を保持する。
- G09：施設の座標と回収サービスを別々に照合する。改修予定日が過ぎたことだけで回収再開と判定しない。通常の家庭ごみ集積所を地図に載せない。
- G10：通常情報は週次、お知らせは日次。取得失敗と変更なしを区別し、ページからリンクされるPDFの変更も検出する。LLM候補の自動公開は行わない。
- ごみ案内の利用条件：問い合わせ文案にある保管・データ化・翻訳・配布・定期取得の範囲を確認し、回答根拠と対象URLを登録簿へ追加する。
