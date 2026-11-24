# php-rule-skills

- `devbox run -- task check` runs ShellCheck and the shunit2 tests, and fails on any problem.
- `devbox run -- task lint-file -- <files>` runs ShellCheck on the given shell scripts.

Scripts in `shared/` are linked into each skill and source that skill's `scripts/rule-kind.sh`, so ShellCheck and the tests reach them through `skills/*/scripts/`, never directly.
