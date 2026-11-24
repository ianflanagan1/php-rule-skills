#!/usr/bin/env bash
#
# Runs every check a rule package must pass before it's committed or published: no unfilled
# template placeholders, the checks in rule-kind.sh for this kind of rule, a valid
# composer.json, PHPUnit, PHPStan, Pint and Infection.
#
# Usage: check.sh <package-dir>
#
# Composer and the tools run in a Docker image built from ../docker, so Docker must be running.
# Exits 0 when every check passes, 1 otherwise.

set -o errexit -o nounset -o pipefail

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/lib.sh"

die() {
    echo "check: $*" >&2
    exit 1
}

[ $# -eq 1 ] || die "usage: check.sh <package-dir>"
dir=$(cd "$1" 2>/dev/null && pwd) || die "no such directory: $1"

if placeholders=$(grep --recursive --line-number --extended-regexp "__(NAME|PASCAL|SNAKE|PACKAGE|NAMESPACE|NAMESPACE_JSON|DESCRIPTION|YEAR|$CLAUDE_PLACEHOLDERS)__" "$dir" --exclude-dir=vendor --exclude-dir=.git); then
    echo "$placeholders" >&2
    die "unfilled template placeholders"
fi

rule_kind_checks "$dir" || exit 1

docker info >/dev/null 2>&1 || die "Docker isn't running"
build_image || die "couldn't build the Docker image"

status=0
in_container "$dir" composer validate --strict --no-check-version --quiet || { echo "check: composer.json is invalid" >&2; status=1; }
in_container "$dir" vendor/bin/phpunit --colors=never || status=1
in_container "$dir" vendor/bin/phpstan analyse --no-progress || status=1
in_container "$dir" vendor/bin/pint --test || status=1
# Only once the tests pass: Infection refuses to run against failing ones
[ $status -ne 0 ] || in_container "$dir" vendor/bin/infection --threads=max --no-progress --with-uncovered --show-mutations=0 || status=1

[ $status -eq 0 ] && echo "check: all passed"
exit $status
