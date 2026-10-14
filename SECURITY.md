# セキュリティポリシー / Security Policy

脆弱性を見つけた場合は、**公開のイシューやフォーラムには書かず**、以下の窓口から非公開でお知らせください。

## WordPress プラグイン

[Patchstack Vulnerability Disclosure Program](https://patchstack.com/database/report) から報告してください。プラグインごとの報告ページは次の形式です。

```
https://patchstack.com/database/report/wordpress/plugin/{プラグインのスラッグ}
```

Patchstack が報告の検証・CVE の採番・開発者への通知を行います。

## その他のリポジトリ

GitHub の非公開報告機能からお知らせください。

1. 該当するリポジトリの **Security** タブを開く
2. **Report a vulnerability** をクリックする
3. 内容・再現手順・影響を受けるバージョンを記入する

報告内容は、メンテナーと報告者だけが見られます。報告から1週間以内に返信します。修正後、GitHub Security Advisory として公開し、必要に応じて CVE を採番します。

## 対象バージョン

修正は、各プロジェクトの最新リリースに対してのみ行います。

## Reporting a Vulnerability (English)

Please **do not disclose vulnerabilities publicly**.

- **WordPress plugins:** Report via the [Patchstack Vulnerability Disclosure Program](https://patchstack.com/database/report) (`https://patchstack.com/database/report/wordpress/plugin/{slug}`).
- **Other repositories:** Report privately via the **Security** tab of the affected repository → **Report a vulnerability**. We will respond within one week.

Fixes are provided for the latest release only.
