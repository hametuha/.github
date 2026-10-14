#!/usr/bin/env bash
#
# topic: wordpress-plugin が付いたリポジトリの新規イシューを Organization Project に追加する。
#
# 環境変数:
#   OWNER          Organization 名（デフォルト: hametuha）
#   PROJECT_NUMBER Project 番号（デフォルト: 5）
#   TOPIC          対象リポジトリのトピック（デフォルト: wordpress-plugin）
#   SINCE          この日時以降に作成されたイシューを対象にする（ISO 8601。デフォルト: 3時間前）
#   DRY_RUN        1 なら追加せずに表示のみ
#
# Project への追加は冪等なので、実行間隔より長い時間を遡っても重複は発生しない。
set -euo pipefail

source "$(dirname "$0")/lib.sh"
SINCE="${SINCE:-$(ago 3 hours)}"

echo "Target: ${OWNER} repos with topic '${TOPIC}', issues created since ${SINCE}"

repos=$(plugin_repos)
if [ -z "$repos" ]; then
	echo "No repositories found."
	exit 0
fi

urls=$(gh search issues --owner "$OWNER" --created ">=${SINCE}" --limit 1000 --json url,repository \
	| jq -r --arg repos "$repos" '($repos | split("\n")) as $r | .[] | select(.repository.nameWithOwner | IN($r[])) | .url')

if [ -z "$urls" ]; then
	echo "No new issues."
	exit 0
fi

count=0
while read -r url; do
	if [ "$DRY_RUN" = "1" ]; then
		echo "[dry-run] ${url}"
	else
		gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" > /dev/null
		echo "Added: ${url}"
	fi
	count=$((count + 1))
done <<< "$urls"

echo "${count} issue(s) processed."
