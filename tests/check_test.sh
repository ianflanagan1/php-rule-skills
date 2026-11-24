#!/usr/bin/env bash
# Behaviour of the skill's scripts/check.sh. Run with `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_a_filled_package_passes() {
    dir=$(filled_package foo-bar)
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 0 $?
    assertContains "$out" 'check: all passed'
}

test_runs_composer_validate_phpunit_phpstan_pint_and_infection_in_docker() {
    dir=$(filled_package foo-bar)
    bash "$scripts/check.sh" "$dir" >/dev/null 2>&1
    for tool in 'composer validate' vendor/bin/phpunit 'vendor/bin/phpstan analyse' 'vendor/bin/pint --test' vendor/bin/infection; do
        assertTrue "didn't run $tool" "called '$tool'"
    done
}

test_an_unfilled_placeholder_fails_and_is_shown() {
    dir=$(filled_package foo-bar)
    echo '__WHAT_IT_REPORTS__' >>"$dir/README.md"
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'README.md:'
    assertContains "$out" 'unfilled template placeholders'
}

test_placeholders_in_vendor_are_ignored() {
    dir=$(filled_package foo-bar)
    mkdir -p "$dir/vendor/x"
    echo '__NAME__' >"$dir/vendor/x/f"
    bash "$scripts/check.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
}

test_a_rule_without_a_literal_identifier_fails() {
    dir=$(filled_package foo-bar)
    rule_with_identifiers "$dir/src/FooBarRule.php"
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "no ->identifier('...')"
}

test_an_identifier_missing_from_the_readme_fails() {
    dir=$(filled_package foo-bar)
    rule_with_identifiers "$dir/src/FooBarRule.php" foo.bar foo.baz
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "the README's @phpstan-ignore identifiers don't match the rule's"
}

test_a_readme_identifier_the_rule_doesnt_have_fails() {
    dir=$(filled_package foo-bar)
    echo 'Add // @phpstan-ignore foo.old to the line.' >>"$dir/README.md"
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "don't match"
}

test_every_identifier_documented_passes() {
    dir=$(filled_package foo-bar)
    rule_with_identifiers "$dir/src/FooBarRule.php" foo.bar foo.baz
    echo 'Add // @phpstan-ignore foo.baz to the line.' >>"$dir/README.md"
    bash "$scripts/check.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
}

test_a_failing_tool_fails_the_check_after_the_other_tools_run() {
    dir=$(filled_package foo-bar)
    fail_when vendor/bin/pint
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertNotContains "$out" 'all passed'
    assertTrue "skipped phpstan" "called 'vendor/bin/phpstan'"
}

test_infection_runs_only_once_the_rest_pass() {
    dir=$(filled_package foo-bar)
    fail_when vendor/bin/phpunit
    bash "$scripts/check.sh" "$dir" >/dev/null 2>&1
    assertFalse "ran infection" "called vendor/bin/infection"
}

test_an_invalid_composer_json_fails() {
    dir=$(filled_package foo-bar)
    fail_when 'composer validate'
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'composer.json is invalid'
}

test_without_docker_running_it_fails() {
    dir=$(filled_package foo-bar)
    fail_when 'docker info'
    out=$(bash "$scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "Docker isn't running"
}

test_a_missing_directory_fails() {
    out=$(bash "$scripts/check.sh" "$sandbox/nope" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no such directory'
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
