#!/usr/bin/env bash
# Behaviour of the skill's scripts/release.sh. Run with `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_commits_everything_as_add_rule_with_the_description_as_body() {
    dir=$(filled_package foo-bar)
    bash "$scripts/release.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertEquals 'Add FooBarRule

A PHPStan rule that reports foo.' "$(git -C "$dir" log --format=%B -1 | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"
    assertEquals '' "$(git -C "$dir" status --porcelain)"
}

test_tags_the_commit_v0_1_0() {
    dir=$(filled_package foo-bar)
    bash "$scripts/release.sh" "$dir" >/dev/null 2>&1
    assertEquals "$(git -C "$dir" rev-parse HEAD)" "$(git -C "$dir" rev-parse 'v0.1.0^{commit}')"
}

test_a_failing_check_commits_nothing() {
    dir=$(filled_package foo-bar)
    fail_when vendor/bin/phpunit
    out=$(bash "$scripts/release.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'check.sh failed'
    assertFalse "committed" "git -C '$dir' rev-parse --verify --quiet HEAD"
}

test_running_again_after_a_release_changes_nothing() {
    dir=$(filled_package foo-bar)
    bash "$scripts/release.sh" "$dir" >/dev/null 2>&1
    out=$(bash "$scripts/release.sh" "$dir" 2>&1)
    assertEquals 0 $?
    assertContains "$out" 'v0.1.0 already tagged'
    assertEquals 1 "$(git -C "$dir" rev-list --count HEAD)"
}

test_a_commit_left_untagged_is_tagged() {
    dir=$(filled_package foo-bar)
    bash "$scripts/release.sh" "$dir" >/dev/null 2>&1
    git -C "$dir" tag --delete v0.1.0 >/dev/null
    out=$(bash "$scripts/release.sh" "$dir" 2>&1)
    assertEquals 0 $?
    assertContains "$out" 'tagged v0.1.0'
    assertEquals 1 "$(git -C "$dir" rev-list --count HEAD)"
}

test_changes_after_the_first_commit_are_left_for_the_user() {
    dir=$(filled_package foo-bar)
    bash "$scripts/release.sh" "$dir" >/dev/null 2>&1
    echo change >>"$dir/README.md"
    out=$(bash "$scripts/release.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'uncommitted changes'
    assertEquals 1 "$(git -C "$dir" rev-list --count HEAD)"
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
