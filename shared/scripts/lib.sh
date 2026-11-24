# shellcheck shell=bash
# Shared by the scripts next to this file. Source it; don't run it.
#
# Each skill links these scripts into its own scripts/ folder, next to its rule-kind.sh, which
# says what differs between kinds of rule: the package prefix, namespace, class suffix and the
# checks only that kind needs.

# shellcheck source-path=SCRIPTDIR
. "$(dirname "${BASH_SOURCE[0]}")/rule-kind.sh"

IMAGE=ianf-php-rule

# The PascalCase form of a kebab-case name: inferable-var-tag-name → InferableVarTagName
pascal_case() {
    perl -pe 's/(?:^|-)(.)/\U$1/g' <<<"$1"
}

# The snake_case form of a kebab-case name: inferable-var-tag-name → inferable_var_tag_name
snake_case() {
    echo "${1//-/_}"
}

# Checks the fixtures in the package directory $1's FIXTURE_DIR, for the kinds of rule whose
# test runs each one through the rule. When one fails, says why on stderr and returns 1.
#
# The test runs only the *.php.inc files there, so anything else would be silently skipped. A
# fixture with a ----- line shows code the rule changes; one without, code it must leave alone.
# There must be at least one of each.
check_before_after_fixtures() {
    local fixtures=$1/$FIXTURE_DIR file changed=0 unchanged=0
    for file in "$fixtures"/* "$fixtures"/.[!.]*; do
        [ -e "$file" ] || continue
        case $file in
            *.php.inc) ;;
            *)
                echo "check: $file isn't a .php.inc fixture, so the test skips it" >&2
                return 1
                ;;
        esac
        if grep --quiet --line-regexp -- '-----' "$file"; then
            changed=$((changed + 1))
        else
            unchanged=$((unchanged + 1))
        fi
    done

    if [ $changed -eq 0 ]; then
        echo "check: no fixture in $FIXTURE_DIR/ with a ----- line; add one showing code the rule changes" >&2
        return 1
    fi
    if [ $unchanged -eq 0 ]; then
        echo "check: no fixture in $FIXTURE_DIR/ without a ----- line; add one showing code the rule must leave alone" >&2
        return 1
    fi
}

# Builds the image from ../docker, which is quick once Docker has cached it. Prints Docker's
# output only when the build fails.
build_image() {
    local output
    output=$(docker build --quiet --tag "$IMAGE" "$(dirname "${BASH_SOURCE[0]}")/../docker" 2>&1) || {
        echo "$output" >&2
        return 1
    }
}

# Runs a command in the image with the package directory $1 mounted as the working directory
in_container() {
    local dir=$1
    shift
    docker run --rm --user "$(id -u):$(id -g)" --env COMPOSER_HOME=/tmp/composer \
        --env GIT_CONFIG_COUNT=1 --env GIT_CONFIG_KEY_0=safe.directory --env GIT_CONFIG_VALUE_0=/app \
        --volume "$dir":/app --workdir /app "$IMAGE" "$@"
}
