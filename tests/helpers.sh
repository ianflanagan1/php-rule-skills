# shellcheck shell=bash
# Shared by the *_test.sh files; sourced, not run.
# shellcheck disable=SC2034  # variables are used by the files that source this
#
# Every test runs in a fresh temporary directory with HOME inside it, and with stub docker,
# curl, github and packagist commands first on the PATH, so no test needs Docker, the network
# or credentials. Each stub appends its command line to $calls. A stub fails when its command
# line contains a string given to fail_when; curl, which scaffold.sh uses to ask Packagist
# whether a name is taken, fails unless its URL contains a string given to on_packagist.

root=$(cd "$(dirname "$0")/.." && pwd)
skill=$root/skills/ianf-new-phpstan-rule
scripts=$skill/scripts
rector_scripts=$root/skills/ianf-new-rector-rule/scripts
cs_fixer_scripts=$root/skills/ianf-new-php-cs-fixer-rule/scripts

# The PATH without the directories that hold the real github and packagist. Taken here rather
# than when sourced, because shunit2 puts its default hooks on the PATH before it runs this.
oneTimeSetUp() {
    base_path=$(
        IFS=:
        kept=
        for d in $PATH; do
            [ -e "$d/github" ] || [ -e "$d/packagist" ] || kept=$kept${kept:+:}$d
        done
        echo "$kept"
    )
}

setUp() {
    sandbox=$(mktemp -d "${SHUNIT_TMPDIR:-${TMPDIR:-/tmp}}/test.XXXXXX")
    sandbox=$(cd "$sandbox" && pwd -P)
    HOME=$sandbox/home
    PHPSTAN_RULES_DIR=$sandbox/rules
    RECTOR_RULES_DIR=$sandbox/rector-rules
    PHP_CS_FIXER_RULES_DIR=$sandbox/php-cs-fixer-rules
    calls=$sandbox/calls
    fails=$sandbox/fails
    packagist=$sandbox/packagist
    stubs=$sandbox/bin
    export HOME PHPSTAN_RULES_DIR RECTOR_RULES_DIR PHP_CS_FIXER_RULES_DIR calls fails packagist
    mkdir -p "$HOME" "$stubs"
    : >"$calls"
    : >"$fails"
    : >"$packagist"
    # shellcheck disable=SC2016  # the stub bodies expand when the stubs run
    for command in docker github packagist; do
        stub "$command" '[ -s "$fails" ] && printf "%s\n" "$line" | grep --quiet --fixed-strings --file="$fails" && exit 1; exit 0'
    done
    # shellcheck disable=SC2016
    stub curl '[ -s "$packagist" ] && printf "%s\n" "$line" | grep --quiet --fixed-strings --file="$packagist" && exit 0; exit 22'
    PATH=$stubs:$base_path
    git config --global user.name test
    git config --global user.email test@example.com
    git config --global commit.gpgsign false
    git config --global tag.gpgsign false
    cd "$sandbox" || return 1
}

tearDown() {
    cd / && rm -rf "$sandbox"
}

# stub command body: a command that logs its command line to $calls, then runs body with the
# line in $line
stub() {
    cat >"$stubs/$1" <<EOF
#!/bin/sh
line="\$(basename "\$0") \$*"
printf '%s\n' "\$line" >>"\$calls"
$2
EOF
    chmod +x "$stubs/$1"
}

fail_when() { printf '%s\n' "$1" >>"$fails"; }
on_packagist() { printf '%s\n' "$1" >>"$packagist"; }

# called text: whether a stub was called with a command line containing text
called() { grep --quiet --fixed-strings -- "$1" "$calls"; }

# scaffold name: scaffold the package name with a fixed description, discarding the output
scaffold() { bash "$scripts/scaffold.sh" "$1" 'A PHPStan rule that reports foo.' >/dev/null 2>&1; }

# filled_package name: scaffold the package name and fill in what the skill leaves to Claude, as
# a rule with the one identifier foo.bar, then clear $calls. Prints the package directory.
filled_package() {
    scaffold "$1" || fail "scaffold.sh failed"
    local dir=$PHPSTAN_RULES_DIR/$1 pascal
    pascal=$(perl -pe 's/(?:^|-)(.)/\U$1/g' <<<"$1")
    rule_with_identifiers "$dir/src/${pascal}Rule.php" foo.bar
    perl -pi -e 's/__WHAT_IT_REPORTS__/Reports foo./; s/__IDENTIFIER__/foo.bar/g' "$dir/README.md"
    : >"$calls"
    echo "$dir"
}

# rule_with_identifiers file identifier...: write a rule class to file whose errors have the
# identifiers given, as string literals
rule_with_identifiers() {
    local file=$1 identifier errors=
    shift
    for identifier; do
        errors="$errors        \$errors[] = RuleErrorBuilder::message('Foo.')->identifier('$identifier')->build();
"
    done
    cat >"$file" <<EOF
<?php
/** Reports foo. */
final class FooRule
{
    public function processNode(): array
    {
$errors        return \$errors;
    }
}
EOF
}

# filled_rector_package name: scaffold the Rector package name and fill in what the skill
# leaves to Claude, with one fixture the rule changes and one it leaves alone, then clear
# $calls. Prints the package directory.
filled_rector_package() {
    bash "$rector_scripts/scaffold.sh" "$1" 'A Rector rule that changes foo.' >/dev/null 2>&1 || fail "scaffold.sh failed"
    local dir=$RECTOR_RULES_DIR/$1
    find "$dir/src" -type f -exec perl -pi -e 's/__(RULE_DOC|SUMMARY|BEFORE|AFTER)__/Foo./g' {} +
    perl -pi -e 's/__WHAT_IT_CHANGES__/Changes foo./' "$dir/README.md"
    fixture "$dir/tests/Fixture/foo_is_changed.php.inc" changed
    fixture "$dir/tests/Fixture/bar_is_left_alone.php.inc" unchanged
    : >"$calls"
    echo "$dir"
}

# fixture file changed|unchanged: write a Rector fixture, with a ----- line when changed
fixture() {
    if [ "$2" = changed ]; then
        printf '<?php\nfoo();\n?>\n-----\n<?php\nbar();\n?>\n' >"$1"
    else
        printf '<?php\nbar();\n?>\n' >"$1"
    fi
}

# filled_cs_fixer_package name: scaffold the PHP-CS-Fixer package name and fill in what the
# skill leaves to Claude, with one fixture the fixer changes and one it leaves alone, then
# clear $calls. Prints the package directory.
filled_cs_fixer_package() {
    bash "$cs_fixer_scripts/scaffold.sh" "$1" 'A PHP-CS-Fixer rule that changes foo.' >/dev/null 2>&1 || fail "scaffold.sh failed"
    local dir=$PHP_CS_FIXER_RULES_DIR/$1
    find "$dir/src" -type f -exec perl -pi -e 's/__(RULE_DOC|SUMMARY|SAMPLE)__/Foo./g' {} +
    perl -pi -e 's/__WHAT_IT_CHANGES__/Changes foo./' "$dir/README.md"
    fixture "$dir/tests/Fixture/foo_is_changed.php.inc" changed
    fixture "$dir/tests/Fixture/bar_is_left_alone.php.inc" unchanged
    : >"$calls"
    echo "$dir"
}

# released_package name: a package directory with one commit, tagged v0.1.0. Prints it.
released_package() {
    local dir=$sandbox/packages/$1
    mkdir -p "$dir"
    git -C "$dir" init --quiet --initial-branch main
    echo x >"$dir/f"
    git -C "$dir" add --all
    git -C "$dir" commit --quiet --message init
    git -C "$dir" tag v0.1.0
    echo "$dir"
}

# Locate shunit2: $SHUNIT2, else on PATH (devbox)
shunit2_path() { echo "${SHUNIT2:-$(command -v shunit2)}"; }
