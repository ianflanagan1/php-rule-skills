#!/usr/bin/env bash
# Behaviour of the scripts as ianf-new-rector-rule runs them, set by its scripts/rule-kind.sh.
# What the scripts do for every kind of rule is in the tests named for each script. Run with
# `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_scaffold_names_the_package_namespace_and_rector_class_from_the_name() {
    bash "$rector_scripts/scaffold.sh" foo-bar 'A Rector rule that changes foo.' >/dev/null 2>&1
    assertEquals 0 $?
    dir=$RECTOR_RULES_DIR/foo-bar
    assertContains "$(cat "$dir/composer.json")" '"name": "ianflanagan1/rector-foo-bar"'
    assertContains "$(cat "$dir/composer.json")" '"IanFlanagan\\RectorRules\\FooBar\\": "src/"'
    assertContains "$(cat "$dir/src/FooBarRector.php")" 'namespace IanFlanagan\RectorRules\FooBar;'
    assertContains "$(cat "$dir/src/FooBarRector.php")" 'final class FooBarRector extends AbstractRector'
    assertContains "$(cat "$dir/tests/FooBarRectorTest.php")" 'final class FooBarRectorTest extends AbstractRectorTestCase'
    assertContains "$(cat "$dir/tests/config/configured_rule.php")" '->withRules([FooBarRector::class])'
    assertContains "$(cat "$dir/README.md")" '->withRules([FooBarRector::class])'
}

test_scaffold_creates_the_fixture_directory() {
    bash "$rector_scripts/scaffold.sh" foo-bar 'A Rector rule that changes foo.' >/dev/null 2>&1
    assertTrue "no tests/Fixture" "[ -d '$RECTOR_RULES_DIR/foo-bar/tests/Fixture' ]"
}

test_scaffold_copies_the_shared_template_files_as_regular_files() {
    bash "$rector_scripts/scaffold.sh" foo-bar 'A Rector rule that changes foo.' >/dev/null 2>&1
    dir=$RECTOR_RULES_DIR/foo-bar
    for file in LICENSE .gitignore .gitattributes pint.json infection.json5 phpunit.xml .github/workflows/ci.yml; do
        assertTrue "no $file" "[ -f '$dir/$file' ]"
    done
    assertEquals '' "$(find "$dir" -type l)"
}

test_scaffold_leaves_the_placeholders_only_claude_can_fill() {
    out=$(bash "$rector_scripts/scaffold.sh" foo-bar 'A Rector rule that changes foo.')
    # __DIR__ is PHP's own constant, in the test and its config
    remaining=$(grep --recursive --only-matching --no-filename --extended-regexp '__[A-Z_]+__' "$RECTOR_RULES_DIR/foo-bar" | grep --invert-match --line-regexp __DIR__ | sort --unique | tr '\n' ' ')
    assertEquals '__AFTER__ __BEFORE__ __RULE_DOC__ __SUMMARY__ __WHAT_IT_CHANGES__ ' "$remaining"
    for placeholder in __RULE_DOC__ __SUMMARY__ __BEFORE__ __AFTER__ __WHAT_IT_CHANGES__; do
        assertContains "$out" "$placeholder"
    done
}

test_scaffold_refuses_a_name_taken_on_packagist_as_a_rector_package() {
    on_packagist 'packages/ianflanagan1/rector-foo-bar.json'
    out=$(bash "$rector_scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'ianflanagan1/rector-foo-bar is already on Packagist'
}

test_check_passes_a_filled_package() {
    dir=$(filled_rector_package foo-bar)
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 0 $?
    assertContains "$out" 'check: all passed'
}

test_check_fails_an_unfilled_code_sample() {
    dir=$(filled_rector_package foo-bar)
    echo '__BEFORE__' >>"$dir/src/FooBarRector.php"
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'unfilled template placeholders'
}

test_check_fails_without_a_fixture_the_rule_changes() {
    dir=$(filled_rector_package foo-bar)
    rm "$dir/tests/Fixture/foo_is_changed.php.inc"
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no fixture in tests/Fixture/ with a ----- line'
    assertFalse "ran the tools" "called 'docker run'"
}

test_check_fails_without_a_fixture_the_rule_leaves_alone() {
    dir=$(filled_rector_package foo-bar)
    rm "$dir/tests/Fixture/bar_is_left_alone.php.inc"
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no fixture in tests/Fixture/ without a ----- line'
}

test_check_fails_a_fixture_the_test_would_skip() {
    dir=$(filled_rector_package foo-bar)
    fixture "$dir/tests/Fixture/baz_is_changed.php" changed
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "baz_is_changed.php isn't a .php.inc fixture"
}

test_check_counts_dashes_only_on_a_line_of_their_own_as_the_split() {
    dir=$(filled_rector_package foo-bar)
    rm "$dir/tests/Fixture/foo_is_changed.php.inc"
    printf '<?php\n// ------ not a split\n?>\n' >"$dir/tests/Fixture/dashes_in_a_comment.php.inc"
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'with a ----- line'
}

test_check_fails_with_no_fixtures() {
    dir=$(filled_rector_package foo-bar)
    rm "$dir"/tests/Fixture/*
    out=$(bash "$rector_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no fixture'
}

test_release_commits_as_add_rector() {
    dir=$(filled_rector_package foo-bar)
    bash "$rector_scripts/release.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertEquals 'Add FooBarRector' "$(git -C "$dir" log --format=%s -1)"
}

test_publish_names_the_github_repo_rector_name() {
    dir=$(released_package foo-bar)
    bash "$rector_scripts/publish.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertTrue "wrong repo" "called 'github publish $dir rector-foo-bar'"
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
