#!/usr/bin/env bash
# Structure of skills/ and shared/: each skill links the shared files it uses. Run with
# `devbox run -- task test`.

# shellcheck source=tests/helpers.sh
. "$(dirname "$0")/helpers.sh"

test_every_skill_links_the_shared_scripts_and_docker_image() {
    for s in "$root"/skills/*/; do
        for path in scripts/lib.sh scripts/scaffold.sh scripts/check.sh scripts/release.sh scripts/publish.sh docker; do
            assertTrue "$(basename "$s")/$path isn't a link" "[ -L '$s$path' ]"
        done
    done
}

test_every_skill_has_its_own_rule_kind() {
    for s in "$root"/skills/*/; do
        assertTrue "$(basename "$s") has no rule-kind.sh" "[ -f '$s/scripts/rule-kind.sh' ] && [ ! -L '$s/scripts/rule-kind.sh' ]"
    done
}

test_every_link_in_a_skill_resolves_to_a_shared_file() {
    while IFS= read -r link; do
        target=$(cd "$(dirname "$link")" && cd -P "$(dirname "$(readlink "$link")")" 2>/dev/null && pwd)
        assertTrue "$link is broken" "[ -e '$link' ]"
        assertContains "$link points outside shared/" "$target/" "$root/shared/"
    done < <(find "$root/skills" -type l)
}

test_every_shared_file_is_linked_from_a_skill() {
    while IFS= read -r file; do
        used=false
        while IFS= read -r link; do
            resolved=$(cd "$(dirname "$link")" && cd -P "$(dirname "$(readlink "$link")")" && pwd)/$(basename "$(readlink "$link")")
            case $file in "$resolved" | "$resolved"/*) used=true ;; esac
        done < <(find "$root/skills" -type l)
        assertTrue "no skill links $file" $used
    done < <(find "$root/shared" -type f)
}

test_the_phpstan_skill_copied_with_its_links_followed_scaffolds_a_package() {
    cp -RL "$skill" "$sandbox/vendored"
    bash "$sandbox/vendored/scripts/scaffold.sh" foo-bar 'A PHPStan rule that reports foo.' >/dev/null 2>&1
    assertEquals 0 $?
    assertTrue "no package" "[ -f '$PHPSTAN_RULES_DIR/foo-bar/src/FooBarRule.php' ]"
}

test_the_rector_skill_copied_with_its_links_followed_scaffolds_a_package() {
    cp -RL "$root/skills/ianf-new-rector-rule" "$sandbox/vendored"
    bash "$sandbox/vendored/scripts/scaffold.sh" foo-bar 'A Rector rule that changes foo.' >/dev/null 2>&1
    assertEquals 0 $?
    assertTrue "no package" "[ -f '$RECTOR_RULES_DIR/foo-bar/src/FooBarRector.php' ]"
}

test_the_php_cs_fixer_skill_copied_with_its_links_followed_scaffolds_a_package() {
    cp -RL "$root/skills/ianf-new-php-cs-fixer-rule" "$sandbox/vendored"
    bash "$sandbox/vendored/scripts/scaffold.sh" foo-bar 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1
    assertEquals 0 $?
    assertTrue "no package" "[ -f '$PHP_CS_FIXER_RULES_DIR/foo-bar/src/FooBarFixer.php' ]"
}

# shellcheck disable=SC1090
. "$(shunit2_path)"
