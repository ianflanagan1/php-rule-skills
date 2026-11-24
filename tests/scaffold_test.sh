#!/usr/bin/env bash
# Behaviour of the skill's scripts/scaffold.sh. Run with `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_creates_the_package_in_the_rules_directory_named_for_the_rule() {
    out=$(bash "$scripts/scaffold.sh" foo-bar 'A PHPStan rule that reports foo.')
    assertEquals 0 $?
    assertTrue "no package directory" "[ -f '$PHPSTAN_RULES_DIR/foo-bar/composer.json' ]"
    assertContains "$out" "Created $PHPSTAN_RULES_DIR/foo-bar"
}

test_names_the_package_namespace_and_rule_class_from_the_name() {
    scaffold foo-bar
    dir=$PHPSTAN_RULES_DIR/foo-bar
    assertContains "$(cat "$dir/composer.json")" '"name": "ianflanagan1/phpstan-foo-bar"'
    assertContains "$(cat "$dir/composer.json")" '"IanFlanagan\\PhpstanRules\\FooBar\\": "src/"'
    assertContains "$(cat "$dir/rules.neon")" 'IanFlanagan\PhpstanRules\FooBar\FooBarRule'
    assertContains "$(cat "$dir/src/FooBarRule.php")" 'namespace IanFlanagan\PhpstanRules\FooBar;'
    assertContains "$(cat "$dir/src/FooBarRule.php")" 'final readonly class FooBarRule implements Rule'
    assertContains "$(cat "$dir/tests/FooBarRuleTest.php")" 'final class FooBarRuleTest extends RuleTestCase'
}

test_fills_the_description_and_year() {
    scaffold foo-bar
    dir=$PHPSTAN_RULES_DIR/foo-bar
    assertContains "$(cat "$dir/composer.json")" '"description": "A PHPStan rule that reports foo."'
    assertContains "$(cat "$dir/README.md")" 'A PHPStan rule that reports foo.'
    assertContains "$(cat "$dir/LICENSE")" "Copyright (c) $(date +%Y) Ian Flanagan"
}

test_leaves_the_placeholders_only_claude_can_fill() {
    scaffold foo-bar
    dir=$PHPSTAN_RULES_DIR/foo-bar
    assertContains "$(cat "$dir/src/FooBarRule.php")" '__RULE_DOC__'
    assertContains "$(cat "$dir/README.md")" '__WHAT_IT_REPORTS__'
    assertContains "$(cat "$dir/README.md")" '__IDENTIFIER__'
    remaining=$(grep --recursive --only-matching --no-filename --extended-regexp '__[A-Z_]+__' "$dir" | sort --unique | tr '\n' ' ')
    assertEquals '__IDENTIFIER__ __RULE_DOC__ __WHAT_IT_REPORTS__ ' "$remaining"
}

test_gives_template_dotfiles_their_real_names() {
    scaffold foo-bar
    dir=$PHPSTAN_RULES_DIR/foo-bar
    assertTrue "no .gitignore" "[ -f '$dir/.gitignore' ]"
    assertTrue "no .gitattributes" "[ -f '$dir/.gitattributes' ]"
    assertTrue "no CI workflow" "[ -f '$dir/.github/workflows/ci.yml' ]"
    assertEquals '' "$(cd "$dir" && find . -name '_*' -not -path './.git/*')"
}

test_copies_every_template_file_as_a_regular_file() {
    scaffold foo-bar
    assertEquals '' "$(find "$PHPSTAN_RULES_DIR/foo-bar" -type l)"
}

test_creates_the_fixture_directory() {
    scaffold foo-bar
    assertTrue "no tests/data" "[ -d '$PHPSTAN_RULES_DIR/foo-bar/tests/data' ]"
}

test_starts_a_git_repository_on_main_with_nothing_committed() {
    scaffold foo-bar
    dir=$PHPSTAN_RULES_DIR/foo-bar
    assertEquals main "$(git -C "$dir" symbolic-ref --short HEAD)"
    assertFalse "has a commit" "git -C '$dir' rev-parse --verify --quiet HEAD"
}

test_installs_dev_dependencies_with_composer_in_docker() {
    scaffold foo-bar
    assertTrue "no docker build" "called 'docker build'"
    assertTrue "no composer update" "called 'composer update'"
    assertTrue "not mounted" "called '$PHPSTAN_RULES_DIR/foo-bar:/app'"
}

test_a_name_that_isnt_kebab_case_is_refused() {
    for name in FooBar foo_bar -foo foo- 1foo 'foo bar'; do
        out=$(bash "$scripts/scaffold.sh" "$name" 'A rule.' 2>&1)
        assertEquals "$name" 1 $?
        assertContains "$out" 'must be kebab-case'
    done
    assertFalse "created something" "[ -e '$PHPSTAN_RULES_DIR' ]"
}

test_an_empty_description_is_refused() {
    out=$(bash "$scripts/scaffold.sh" foo-bar '' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'description is empty'
}

test_an_existing_directory_is_left_alone() {
    mkdir -p "$PHPSTAN_RULES_DIR/foo-bar"
    echo mine >"$PHPSTAN_RULES_DIR/foo-bar/f"
    out=$(bash "$scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'already exists'
    assertEquals 'f' "$(ls "$PHPSTAN_RULES_DIR/foo-bar")"
}

test_a_name_taken_on_packagist_is_refused() {
    on_packagist 'packages/ianflanagan1/phpstan-foo-bar.json'
    out=$(bash "$scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'ianflanagan1/phpstan-foo-bar is already on Packagist'
    assertFalse "created the package" "[ -e '$PHPSTAN_RULES_DIR/foo-bar' ]"
}

test_without_docker_running_nothing_is_created() {
    fail_when 'docker info'
    out=$(bash "$scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" "Docker isn't running"
    assertFalse "created the package" "[ -e '$PHPSTAN_RULES_DIR/foo-bar' ]"
}

test_a_failed_composer_install_is_reported() {
    fail_when 'composer update'
    out=$(bash "$scripts/scaffold.sh" foo-bar 'A rule.' 2>&1)
    assertEquals 1 $?
    assertContains "$out" 'composer failed'
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
