#!/usr/bin/env bash
# Behaviour of the scripts as ianf-new-php-cs-fixer-rule runs them, set by its
# scripts/rule-kind.sh. What the scripts do for every kind of rule is in the tests named for each
# script. Run with `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_scaffold_names_the_package_namespace_and_fixer_class_from_the_name() {
    bash "$cs_fixer_scripts/scaffold.sh" foo-bar 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1
    assertEquals 0 $?
    dir=$PHP_CS_FIXER_RULES_DIR/foo-bar
    assertContains "$(cat "$dir/composer.json")" '"name": "ianflanagan1/php-cs-fixer-foo-bar"'
    assertContains "$(cat "$dir/composer.json")" '"IanFlanagan\\PhpCsFixerRules\\FooBar\\": "src/"'
    assertContains "$(cat "$dir/src/FooBarFixer.php")" 'namespace IanFlanagan\PhpCsFixerRules\FooBar;'
    assertContains "$(cat "$dir/src/FooBarFixer.php")" 'final readonly class FooBarFixer implements FixerInterface'
    assertContains "$(cat "$dir/tests/FooBarFixerTest.php")" 'final class FooBarFixerTest extends TestCase'
    assertContains "$(cat "$dir/README.md")" '->registerCustomFixers([new FooBarFixer()])'
}

test_scaffold_names_the_fixer_rule_in_snake_case_under_the_vendor() {
    bash "$cs_fixer_scripts/scaffold.sh" foo-bar-2 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1
    dir=$PHP_CS_FIXER_RULES_DIR/foo-bar-2
    assertContains "$(cat "$dir/src/FooBar2Fixer.php")" "return 'IanFlanagan/foo_bar_2';"
    assertContains "$(cat "$dir/README.md")" "'IanFlanagan/foo_bar_2' => true"
}

test_scaffold_creates_the_fixture_directory() {
    bash "$cs_fixer_scripts/scaffold.sh" foo-bar 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1
    assertTrue "no tests/Fixture" "[ -d '$PHP_CS_FIXER_RULES_DIR/foo-bar/tests/Fixture' ]"
}

test_scaffold_copies_the_shared_template_files_as_regular_files() {
    bash "$cs_fixer_scripts/scaffold.sh" foo-bar 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1
    dir=$PHP_CS_FIXER_RULES_DIR/foo-bar
    for file in LICENSE .gitignore .gitattributes pint.json infection.json5 phpunit.xml phpstan.neon .github/workflows/ci.yml; do
        assertTrue "no $file" "[ -f '$dir/$file' ]"
    done
    assertEquals '' "$(find "$dir" -type l)"
}

test_scaffold_leaves_the_placeholders_only_claude_can_fill() {
    out=$(bash "$cs_fixer_scripts/scaffold.sh" foo-bar 'A PHP-CS-Fixer rule that changes foo.')
    # __DIR__ and __FILE__ are PHP's own constants, in the test
    remaining=$(grep --recursive --only-matching --no-filename --extended-regexp '__[A-Z_]+__' "$PHP_CS_FIXER_RULES_DIR/foo-bar" | grep --invert-match --line-regexp --extended-regexp '__(DIR|FILE)__' | sort --unique | tr '\n' ' ')
    assertEquals '__RULE_DOC__ __SAMPLE__ __SUMMARY__ __WHAT_IT_CHANGES__ ' "$remaining"
    for placeholder in __RULE_DOC__ __SUMMARY__ __SAMPLE__ __WHAT_IT_CHANGES__; do
        assertContains "$out" "$placeholder"
    done
}

test_scaffold_refuses_a_name_taken_on_packagist_as_a_php_cs_fixer_package() {
    on_packagist 'packages/ianflanagan1/php-cs-fixer-foo-bar.json'
    out=$(bash "$cs_fixer_scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'ianflanagan1/php-cs-fixer-foo-bar is already on Packagist'
}

test_check_passes_a_filled_package() {
    dir=$(filled_cs_fixer_package foo-bar)
    out=$(bash "$cs_fixer_scripts/check.sh" "$dir" 2>&1)
    assertEquals 0 $?
    assertContains "$out" 'check: all passed'
}

test_check_fails_an_unfilled_code_sample() {
    dir=$(filled_cs_fixer_package foo-bar)
    echo '__SAMPLE__' >>"$dir/src/FooBarFixer.php"
    out=$(bash "$cs_fixer_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'unfilled template placeholders'
}

test_check_fails_without_a_fixture_the_fixer_changes() {
    dir=$(filled_cs_fixer_package foo-bar)
    rm "$dir/tests/Fixture/foo_is_changed.php.inc"
    out=$(bash "$cs_fixer_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no fixture in tests/Fixture/ with a ----- line'
    assertFalse "ran the tools" "called 'docker run'"
}

test_check_fails_without_a_fixture_the_fixer_leaves_alone() {
    dir=$(filled_cs_fixer_package foo-bar)
    rm "$dir/tests/Fixture/bar_is_left_alone.php.inc"
    out=$(bash "$cs_fixer_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'no fixture in tests/Fixture/ without a ----- line'
}

test_check_fails_a_fixture_the_test_would_skip() {
    dir=$(filled_cs_fixer_package foo-bar)
    fixture "$dir/tests/Fixture/baz_is_changed.php" changed
    out=$(bash "$cs_fixer_scripts/check.sh" "$dir" 2>&1)
    assertEquals 1 $?
    assertContains "$out" "baz_is_changed.php isn't a .php.inc fixture"
}

test_release_commits_as_add_fixer() {
    dir=$(filled_cs_fixer_package foo-bar)
    bash "$cs_fixer_scripts/release.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertEquals 'Add FooBarFixer' "$(git -C "$dir" log --format=%s -1)"
}

test_publish_names_the_github_repo_php_cs_fixer_name() {
    dir=$(released_package foo-bar)
    bash "$cs_fixer_scripts/publish.sh" "$dir" >/dev/null 2>&1
    assertEquals 0 $?
    assertTrue "wrong repo" "called 'github publish $dir php-cs-fixer-foo-bar'"
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
