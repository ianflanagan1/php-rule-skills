# shellcheck shell=bash
# What makes the shared scripts build PHP-CS-Fixer rules. lib.sh sources it; don't run it.
# shellcheck disable=SC2034  # variables are used by the scripts that source lib.sh

# The package is ianflanagan1/<PREFIX>-<name>, and its GitHub repo <PREFIX>-<name>
PREFIX=php-cs-fixer
NAMESPACE_ROOT='IanFlanagan\PhpCsFixerRules'
BASE_DIR=${PHP_CS_FIXER_RULES_DIR:-$HOME/projects/php/php-cs-fixer-rules}
# The rule class is <PascalName><CLASS_SUFFIX>
CLASS_SUFFIX=Fixer
# scaffold.sh creates it, because the template can't hold an empty directory
FIXTURE_DIR=tests/Fixture
# The placeholders scaffold.sh leaves for Claude to fill, as an extended-regexp alternation
CLAUDE_PLACEHOLDERS='RULE_DOC|SUMMARY|SAMPLE|WHAT_IT_CHANGES'

# Prints what's left to fill after scaffold.sh, for the rule class $1
scaffold_todo() {
    cat <<EOF
  rule       src/$1.php (stub: fill __RULE_DOC__, __SUMMARY__, __SAMPLE__, isRisky, getPriority, isCandidate and fix)
  test       tests/$1Test.php runs every fixture in $FIXTURE_DIR/ (add them there)
  README     fill __WHAT_IT_CHANGES__
EOF
}

# check.sh's checks of the package directory $1 that only PHP-CS-Fixer rules need. When one
# fails, says why on stderr and returns 1.
rule_kind_checks() {
    check_before_after_fixtures "$1"
}
