#!/usr/bin/env bash
# Behaviour of the skill's scripts/publish.sh. Run with `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_publishes_to_github_as_phpstan_name_then_to_packagist() {
    dir=$(released_package foo-bar)
    bash "$scripts/publish.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertEquals "github publish $dir phpstan-foo-bar
packagist publish $dir" "$(cat "$calls")"
}

test_an_untagged_package_isnt_published() {
    dir=$(released_package foo-bar)
    git -C "$dir" tag --delete v0.1.0 >/dev/null
    out=$(bash "$scripts/publish.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'run release.sh first'
    assertEquals '' "$(cat "$calls")"
}

test_a_failed_github_publish_stops_before_packagist() {
    dir=$(released_package foo-bar)
    fail_when 'github publish'
    out=$(bash "$scripts/publish.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'github publish failed'
    assertFalse "ran packagist" "called packagist"
}

test_a_failed_packagist_publish_is_reported() {
    dir=$(released_package foo-bar)
    fail_when 'packagist publish'
    out=$(bash "$scripts/publish.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'packagist publish failed'
}

# assert_points_to_the_setup_without command: publish.sh fails before publishing anything when
# command isn't on the PATH, and links to repo-tools' setup
assert_points_to_the_setup_without() {
    dir=$(released_package foo-bar)
    rm "$stubs/$1"
    out=$(bash "$scripts/publish.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "$1 isn't on your PATH"
    assertContains "$out" 'https://github.com/ianflanagan1/repo-tools#setup'
    assertEquals '' "$(cat "$calls")"
}

test_without_github_on_the_path_it_points_to_the_setup() {
    assert_points_to_the_setup_without github
}

test_without_packagist_on_the_path_it_points_to_the_setup() {
    assert_points_to_the_setup_without packagist
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
