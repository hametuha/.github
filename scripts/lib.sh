# 各スクリプトで共有する設定と関数。source して使う。

OWNER="${OWNER:-hametuha}"
PROJECT_NUMBER="${PROJECT_NUMBER:-5}"
TOPIC="${TOPIC:-wordpress-plugin}"
DRY_RUN="${DRY_RUN:-0}"

# N時間前/N日前のUTC日時をISO 8601で返す（GNU date / BSD date 両対応）
ago() {
	date -u -d "$1 $2 ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
		|| date -u -v-"$1""$(echo "$2" | cut -c1 | tr 'hd' 'Hd')" +%Y-%m-%dT%H:%M:%SZ
}

# 対象トピックが付いた、アーカイブされていないリポジトリ（owner/name を改行区切り）
plugin_repos() {
	gh repo list "$OWNER" --topic "$TOPIC" --no-archived --limit 500 --json nameWithOwner --jq '.[].nameWithOwner'
}

# Project の全アイテム（Issueのみ）をJSON配列で返す
project_items() {
	gh api graphql --paginate --slurp -F owner="$OWNER" -F number="$PROJECT_NUMBER" -f query='
		query($owner: String!, $number: Int!, $endCursor: String) {
			organization(login: $owner) {
				projectV2(number: $number) {
					items(first: 100, after: $endCursor) {
						pageInfo { hasNextPage endCursor }
						nodes {
							id
							status: fieldValueByName(name: "Status") {
								... on ProjectV2ItemFieldSingleSelectValue { name }
							}
							content {
								... on Issue {
									url number title state stateReason closedAt
									repository { nameWithOwner name }
									labels(first: 1) { totalCount }
									closedByPullRequestsReferences(first: 1, includeClosedPrs: true) { totalCount }
								}
							}
						}
					}
				}
			}
		}' | jq '[.[].data.organization.projectV2.items.nodes[] | select(.content.url != null)]'
}
