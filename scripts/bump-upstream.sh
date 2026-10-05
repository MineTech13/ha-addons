#!/usr/bin/env bash
# Bump an add-on to the latest upstream release.
# Usage: scripts/bump-upstream.sh <addon-dir>
# Prints "changed=true|false" and "version=<x>" (GITHUB_OUTPUT compatible) on stdout.
set -euo pipefail

cd "$(dirname "$0")/.."
ADDON="${1:?usage: $0 <addon-dir>}"

# add-on dir -> upstream repo + image, from scripts/upstreams.tsv
IFS=$'\t' read -r _ REPO IMAGE < <(grep -v '^#' scripts/upstreams.tsv | awk -F'\t' -v a="$ADDON" '$1 == a') \
    || { echo "$ADDON is not listed in scripts/upstreams.tsv" >&2; exit 2; }
[ -n "${REPO:-}" ] || { echo "$ADDON is not listed in scripts/upstreams.tsv" >&2; exit 2; }

DOCKERFILE="$ADDON/Dockerfile"
CONFIG="$ADDON/config.yaml"
CHANGELOG="$ADDON/CHANGELOG.md"

current="$(sed -n 's/^ARG UPSTREAM_VERSION=//p' "$DOCKERFILE")"
[ -n "$current" ] || { echo "no ARG UPSTREAM_VERSION in $DOCKERFILE" >&2; exit 1; }

# Newest non-draft, non-prerelease release (gh already sorts newest first)
latest="$(gh api "repos/$REPO/releases?per_page=30" \
    --jq '[.[] | select(.draft == false and .prerelease == false)][0].tag_name')"
latest="${latest#v}"
if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    echo "could not read latest release of $REPO" >&2
    exit 1
fi

newest="$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)"
if [ "$latest" = "$current" ] || [ "$newest" != "$latest" ]; then
    echo "$ADDON: up to date ($current)" >&2
    echo "changed=false"
    echo "version=$current"
    exit 0
fi

# The image must actually be published before we point at it
if ! docker manifest inspect "$IMAGE:$latest" >/dev/null 2>&1; then
    echo "$ADDON: release $latest exists but $IMAGE:$latest is not published yet, skipping" >&2
    echo "changed=false"
    echo "version=$current"
    exit 0
fi

sed -i "s/^ARG UPSTREAM_VERSION=.*/ARG UPSTREAM_VERSION=$latest/" "$DOCKERFILE"
sed -i "s/^version: .*/version: \"$latest-0\"/" "$CONFIG"
# CHANGELOGs are oldest-first: append
[ -z "$(tail -c1 "$CHANGELOG")" ] || echo >> "$CHANGELOG"
printf '\n## %s-0\n- Upstream update to %s ([release notes](https://github.com/%s/releases/tag/v%s)).\n' \
    "$latest" "$latest" "$REPO" "$latest" >> "$CHANGELOG"

echo "$ADDON: $current -> $latest" >&2
echo "changed=true"
echo "version=$latest"
