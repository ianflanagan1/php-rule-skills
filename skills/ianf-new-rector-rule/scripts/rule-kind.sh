# shellcheck shell=bash
# What makes the shared scripts build Rector rules. lib.sh sources it; don't run it.
# shellcheck disable=SC2034  # variables are used by the scripts that source lib.sh

# The package is ianflanagan1/<PREFIX>-<name>, and its GitHub repo <PREFIX>-<name>
PREFIX=rector
NAMESPACE_ROOT='IanFlanagan\RectorRules'
BASE_DIR=${RECTOR_RULES_DIR:-$HOME/projects/php/rector-rules}
# The rule class is <PascalName><CLASS_SUFFIX>
CLASS_SUFFIX=Rector
# scaffold.sh creates it, because the template can't hold an empty directory
FIXTURE_DIR=tests/Fixture
# The placeholders scaffold.sh leaves for Claude to fill, as an extended-regexp alternation
CLAUDE_PLACEHOLDERS='RULE_DOC|SUMMARY|BEFORE|AFTER|WHAT_IT_CHANGES'

# Prints what's left to fill after scaffold.sh, for the rule class $1
scaffold_todo() {
    cat <<EOF
  rule       src/$1.php (stub: fill __RULE_DOC__, __SUMMARY__, __BEFORE__, __AFTER__, the node types and refactor)
  test       tests/$1Test.php runs every fixture in $FIXTURE_DIR/ (add them there)
  README     fill __WHAT_IT_CHANGES__
EOF
}

# check.sh's checks of the package directory $1 that only Rector rules need. When one fails,
# says why on stderr and returns 1.
rule_kind_checks() {
    check_before_after_fixtures "$1"
}
