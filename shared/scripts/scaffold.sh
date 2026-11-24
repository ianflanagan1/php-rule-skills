#!/usr/bin/env bash
#
# Creates a new rule package from the skill's template, as its own git repo, and installs its
# dev dependencies. It creates the rule and its test as stubs to fill in; it doesn't write
# their logic, commit or publish.
#
# Usage: scaffold.sh <name> <description>
#
#   name         kebab-case, e.g. inferable-var-tag-name. Becomes the directory <name>, the
#                package ianflanagan1/<prefix>-<name>, the namespace <root>\<PascalName> and
#                the rule class <PascalName><suffix>, with the prefix, root and suffix from
#                rule-kind.sh. Its snake_case form fills __SNAKE__ in the template.
#   description  one sentence for composer.json and the README
#
# The package is created in rule-kind.sh's BASE_DIR. The script stops if the directory exists
# or the package name is taken on Packagist. Composer runs in a Docker image built from
# ../docker, so Docker must be running.

set -o errexit -o nounset -o pipefail

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/lib.sh"

VENDOR=ianflanagan1

die() {
    echo "scaffold: $*" >&2
    exit 1
}

[ $# -eq 2 ] || die "usage: scaffold.sh <name> <description>"
name=$1
description=$2
[[ $name =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] || die "name must be kebab-case, not '$name'"
[ -n "$description" ] || die "description is empty"

template=$(cd "$(dirname "$0")/../template" && pwd -P)
dir="$BASE_DIR/$name"
package="$VENDOR/$PREFIX-$name"
pascal=$(pascal_case "$name")
namespace="$NAMESPACE_ROOT\\$pascal"

[ ! -e "$dir" ] || die "$dir already exists"
if curl --fail --silent --show-error --output /dev/null "https://packagist.org/packages/$package.json" 2>/dev/null; then
    die "$package is already on Packagist"
fi
docker info >/dev/null 2>&1 || die "Docker isn't running"
build_image || die "couldn't build the Docker image"

mkdir -p "$BASE_DIR"
# Following links, as the template links the files every kind of rule shares
cp -RL "$template" "$dir"
cd "$dir"

# Template dotfiles are stored with a _ prefix so they don't act on the skill's own repo
for entry in _*; do
    mv "$entry" ".${entry#_}"
done

mkdir -p "$FIXTURE_DIR"

NAME=$name PASCAL=$pascal SNAKE=$(snake_case "$name") PACKAGE=$package NAMESPACE=$namespace DESCRIPTION=$description YEAR=$(date +%Y) \
    find . -type f -not -path './.git/*' -exec perl -pi -e '
        s/__NAMESPACE_JSON__/$ENV{NAMESPACE} =~ s{\\}{\\\\}gr/ge;
        s/__NAMESPACE__/$ENV{NAMESPACE}/g;
        s/__PASCAL__/$ENV{PASCAL}/g;
        s/__SNAKE__/$ENV{SNAKE}/g;
        s/__PACKAGE__/$ENV{PACKAGE}/g;
        s/__NAME__/$ENV{NAME}/g;
        s/__DESCRIPTION__/$ENV{DESCRIPTION}/g;
        s/__YEAR__/$ENV{YEAR}/g;
    ' {} +

# The stubs for the rule and its test are stored with __PASCAL__ in their names
find . -type f -name '*__PASCAL__*' -not -path './.git/*' | while IFS= read -r stub; do
    mv "$stub" "${stub//__PASCAL__/$pascal}"
done

git init --quiet --initial-branch main

in_container "$dir" composer update --no-interaction --no-progress \
    || die "composer failed; Docker must be able to mount $dir (Docker Desktop shares /Users by default)"

cat <<EOF
Created $dir
  package    $package
  namespace  $namespace
$(scaffold_todo "$pascal$CLASS_SUFFIX")
EOF
