#!/usr/bin/env bash
#
# Project のアイテムの Status をイシューの状態に合わせて進める。後戻りはさせない。
#
#   - PRと紐づいた（Status が空 / Todo） → In Progress
#   - イシューが閉じられた（Done 以外）   → Done
#
# 環境変数は lib.sh を参照。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

project=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq '.id')
field=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq '.fields[] | select(.name == "Status")')
field_id=$(jq -r '.id' <<< "$field")
option_id() {
	jq -r --arg n "$1" '.options[] | select(.name == $n) | .id' <<< "$field"
}

changes=$(project_items | jq -r '.[] | (.status.name // "") as $s |
	if .content.state == "CLOSED" and $s != "Done" then [.id, "Done", .content.url]
	elif .content.state == "OPEN" and ($s == "" or $s == "Todo") and .content.closedByPullRequestsReferences.totalCount > 0 then [.id, "In Progress", .content.url]
	else empty end | @tsv')

if [ -z "$changes" ]; then
	echo "No status changes."
	exit 0
fi

while IFS=$'\t' read -r item status url; do
	if [ "$DRY_RUN" = "1" ]; then
		echo "[dry-run] ${status}: ${url}"
	else
		gh project item-edit --project-id "$project" --id "$item" --field-id "$field_id" \
			--single-select-option-id "$(option_id "$status")" > /dev/null
		echo "${status}: ${url}"
	fi
done <<< "$changes"
