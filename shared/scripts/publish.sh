#!/usr/bin/env bash
#
# Publishes a released rule package: creates its GitHub repo <prefix>-<name>, with the prefix
# from rule-kind.sh, and pushes to it, then submits it to Packagist, with the github and
# packagist commands from repo-tools. Each step is skipped when already done, so after a
# failure fix the cause and run it again.
#
# Usage: publish.sh <package-dir>

set -o errexit -o nounset -o pipefail

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/lib.sh"

SETUP=https://github.com/ianflanagan1/repo-tools#setup

die() {
    echo "publish: $*" >&2
    exit 1
}

[ $# -eq 1 ] || die "usage: publish.sh <package-dir>"
dir=$(cd "$1" 2>/dev/null && pwd) || die "no such directory: $1"

for command in github packagist; do
    command -v "$command" >/dev/null || die "$command isn't on your PATH; set it up as $SETUP says"
done
git -C "$dir" describe --tags --abbrev=0 >/dev/null 2>&1 || die "$dir has no tag; run release.sh first"

github publish "$dir" "$PREFIX-$(basename "$dir")" || die "github publish failed; if it's credentials, see $SETUP"
packagist publish "$dir" || die "packagist publish failed; if it's credentials, see $SETUP"
