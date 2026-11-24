# shellcheck shell=bash
# What makes the shared scripts build PHPStan rules. lib.sh sources it; don't run it.
# shellcheck disable=SC2034  # variables are used by the scripts that source lib.sh

# The package is ianflanagan1/<PREFIX>-<name>, and its GitHub repo <PREFIX>-<name>
PREFIX=phpstan
NAMESPACE_ROOT='IanFlanagan\PhpstanRules'
BASE_DIR=${PHPSTAN_RULES_DIR:-$HOME/projects/php/phpstan-rules}
# The rule class is <PascalName><CLASS_SUFFIX>
CLASS_SUFFIX=Rule
# scaffold.sh creates it, because the template can't hold an empty directory
FIXTURE_DIR=tests/data
# The placeholders scaffold.sh leaves for Claude to fill, as an extended-regexp alternation
CLAUDE_PLACEHOLDERS='RULE_DOC|WHAT_IT_REPORTS|IDENTIFIER'

# Prints what's left to fill after scaffold.sh, for the rule class $1
scaffold_todo() {
    cat <<EOF
  rule       src/$1.php (stub: fill __RULE_DOC__, the node type and processNode)
  test       tests/$1Test.php (stub: add tests), fixtures in $FIXTURE_DIR/
  README     fill __WHAT_IT_REPORTS__ and __IDENTIFIER__
EOF
}

# check.sh's checks of the package directory $1 that only PHPStan rules need. When one fails,
# says why on stderr and returns 1.
#
# Every identifier passed as a string literal to ->identifier() in src/ must be one the README
# tells users to ignore with @phpstan-ignore, and the other way round.
rule_kind_checks() {
    local dir=$1 identifiers documented
    identifiers=$(grep --recursive --only-matching --no-filename --extended-regexp \
        --regexp="->identifier\(['\"][^'\"]+['\"]\)" "$dir/src" \
        | perl -pe 's/^->identifier\(.(.*).\)$/$1/' | sort --unique) || true
    documented=$(grep --only-matching --extended-regexp '@phpstan-ignore [A-Za-z0-9.]+' "$dir/README.md" \
        | perl -pe 's/^\@phpstan-ignore //' | sort --unique) || true

    if [ -z "$identifiers" ]; then
        echo "check: no ->identifier('...') with a string literal in src/; give every error one" >&2
        return 1
    fi
    if [ "$identifiers" != "$documented" ]; then
        echo "  in src/:    $(tr '\n' ' ' <<<"$identifiers")" >&2
        echo "  in README:  $(tr '\n' ' ' <<<"$documented")" >&2
        echo "check: the README's @phpstan-ignore identifiers don't match the rule's" >&2
        return 1
    fi
}
