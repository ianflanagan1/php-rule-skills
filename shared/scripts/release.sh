#!/usr/bin/env bash
#
# Commits a new rule package as its first commit and tags it v0.1.0, once check.sh passes.
# The commit is "Add <PascalName><suffix>", with the class suffix from rule-kind.sh and the
# description from composer.json as its body. Each step is skipped when already done, so
# after a failure fix the cause and run it again.
#
# Usage: release.sh <package-dir>

set -o errexit -o nounset -o pipefail

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/lib.sh"

TAG=v0.1.0

die() {
    echo "release: $*" >&2
    exit 1
}

[ $# -eq 1 ] || die "usage: release.sh <package-dir>"
dir=$(cd "$1" 2>/dev/null && pwd) || die "no such directory: $1"

"$(dirname "$0")/check.sh" "$dir" || die "check.sh failed; fix it and run release.sh again"

cd "$dir"
class=$(pascal_case "$(basename "$dir")")$CLASS_SUFFIX
description=$(perl -MJSON::PP -0777 -ne 'print decode_json($_)->{description}' composer.json)
[ -n "$description" ] || die "composer.json has no description"

if ! git rev-parse --verify --quiet HEAD >/dev/null; then
    git add --all
    git commit --quiet --message "Add $class" --message "$description"
    echo "release: committed Add $class"
elif [ -n "$(git status --porcelain)" ]; then
    die "$dir already has commits and also uncommitted changes; commit those yourself"
fi

if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "release: $TAG already tagged"
else
    git tag "$TAG"
    echo "release: tagged $TAG"
fi
