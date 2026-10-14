#!/usr/bin/env bash
#
# 直近1週間の成果（リリース・完了イシュー・マージPR）を Slack に投稿する。
# 成果がゼロの週は投稿しない。
#
# 環境変数（lib.sh の他）:
#   SLACK_WEBHOOK_URL 投稿先の Incoming Webhook
#   SINCE             集計開始日時（ISO 8601。デフォルト: 7日前）
#   DRY_RUN           1 なら投稿せずにメッセージを表示
set -euo pipefail
source "$(dirname "$0")/lib.sh"
SINCE="${SINCE:-$(ago 7 days)}"

repos=$(plugin_repos)
repos_json=$(jq -R . <<< "$repos" | jq -s .)

# リリース（ドラフトを除く）
releases=$(while read -r repo; do
	gh release list -R "$repo" -L 20 --exclude-drafts --json tagName,publishedAt \
		| jq --arg repo "$repo" --arg since "$SINCE" '.[] | select(.publishedAt >= $since) | {repo: ($repo | split("/")[1]), tag: .tagName, url: "https://github.com/\($repo)/releases/tag/\(.tagName)"}'
done <<< "$repos" | jq -s .)

# 完了したイシュー（not planned を除く）
issues=$(project_items | jq --arg since "$SINCE" '[.[].content | select(.state == "CLOSED" and .stateReason == "COMPLETED" and .closedAt >= $since)]')

# マージしたPR（botを除く）
prs=$(gh search prs --owner "$OWNER" --merged-at ">=${SINCE}" --limit 200 --json url,number,title,repository,author \
	| jq --argjson repos "$repos_json" '[.[] | select((.repository.nameWithOwner | IN($repos[])) and (.author.is_bot | not))]')

total=$(jq -n --argjson a "$releases" --argjson b "$issues" --argjson c "$prs" '($a + $b + $c) | length')
if [ "$total" = "0" ]; then
	echo "No achievements since ${SINCE}. Skip posting."
	exit 0
fi

from=$(TZ=Asia/Tokyo date -d "$SINCE" +%-m/%-d 2>/dev/null || TZ=Asia/Tokyo date -j -u -f %Y-%m-%dT%H:%M:%SZ "$SINCE" +%-m/%-d)
to=$(TZ=Asia/Tokyo date +%-m/%-d)
project_url="https://github.com/orgs/${OWNER}/projects/${PROJECT_NUMBER}"

text=$(jq -rn --argjson rel "$releases" --argjson iss "$issues" --argjson pr "$prs" \
	--arg from "$from" --arg to "$to" --arg project "$project_url" '
	def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
	# 同じタイトルは「×N」で1行にまとめ、件数の多い順に最大10行
	def section($icon; $heading; items; line):
		(items | group_by(.title) | map(if length > 1 then {title: .[0].title, count: length} else .[0] end)
			| sort_by(-(.count // 1))) as $g
		| if (items | length) > 0 then
			"\n\($icon) *\($heading) \(items | length)件*\n"
			+ ($g[:10] | map("• " + if .count then "\(.title | esc) ×\(.count)" else line end) | join("\n"))
			+ (if ($g | length) > 10 then "\n• ほか \(($g | length) - 10)件" else "" end)
		else "" end;
	"🔌 *破滅派プラグイン 今週の成果*（\($from)〜\($to)）\n"
	+ section("🚀"; "リリース"; $rel | map(.title = .url); "<\(.url)|\(.repo) \(.tag)>")
	+ section("✅"; "完了したイシュー"; $iss; "<\(.url)|\(.repository.name)#\(.number)> \(.title | esc)")
	+ section("🔀"; "マージしたPR"; $pr; "<\(.url)|\(.repository.name)#\(.number)> \(.title | esc)")
	+ "\n\n<\($project)|ボードを見る>"')

if [ "$DRY_RUN" = "1" ]; then
	echo "$text"
	exit 0
fi

jq -n --arg text "$text" '{text: $text, unfurl_links: false}' \
	| curl -fsS -X POST -H 'Content-Type: application/json' --data @- "$SLACK_WEBHOOK_URL" > /dev/null
echo "Posted."
