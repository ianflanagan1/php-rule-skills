---
name: ianf-new-phpstan-rule
description: Create a new custom PHPStan rule as its own Composer package (ianflanagan1/phpstan-<name>), test-first, and optionally publish it to GitHub and Packagist. Use when the user wants a PHPStan rule that enforces a convention, especially one to reuse across projects.
argument-hint: <what the rule should report>
disable-model-invocation: true
model: inherit
allowed-tools: Bash(bash *scripts/scaffold.sh*), Bash(bash *scripts/check.sh*), Bash(bash *scripts/release.sh*), Bash(bash *scripts/publish.sh*)
---

# New PHPStan rule

Build one PHPStan rule as its own package in `~/projects/php/phpstan-rules/<name>/`, from the template next to this file. The scripts in `scripts/` do the mechanical steps; you do the parts that need judgement. Run them as `bash "${CLAUDE_SKILL_DIR}/scripts/<script>.sh" …`.

## 1. Settle the name and description

- **Name:** kebab-case, naming what the rule reports or enforces, e.g. `inferable-var-tag-name`. It becomes the package `ianflanagan1/phpstan-<name>`, which is permanent once on Packagist. Unless the user gave one, propose one or two and wait for their choice.
- **Description:** one sentence, starting "A PHPStan rule that reports …". It also becomes the body of the package's first commit.

## 2. Find out what PHPStan actually does

Before encoding an assumption about PHPStan's behaviour in the rule, probe it: write a scratch file, analyse it at level 9 with `PHPStan\dumpType()`, and read the result. For example, check that the fix the rule will ask for really works in every place the rule reports. Note which cases the probes settled; they become fixtures.

## 3. Scaffold

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/scaffold.sh" <name> "<description>"
```

It creates the package (with its own git repo) with stubs for the rule and its test, installs dev dependencies with Docker, and prints the class, namespace and what's left to fill. It stops if the directory exists, the name is taken on Packagist or Docker isn't running.

## 4. Tests first

Add tests to the stub `tests/<Pascal>RuleTest.php`:

- One test method per behaviour, named for it: `test_a_var_tag_naming_the_assigned_variable_is_reported`.
- One fixture file per test in `tests/data/`, with namespace `<rule namespace>\Tests\data\<FixtureName>`. Fixtures are classmap-autoloaded, which PHPStan needs to analyse traits.
- Cover what must be reported **and** what must not: near-misses, other syntax for the same thing, closures, traits.
- `$this->analyse([file], [[message, line, tip?], ...])`. If the rule needs services like `FileTypeMapper`, get them in `getRule()` from `self::getContainer()->getByType(...)`.

Run `check.sh <dir>` and see the tests fail before writing the rule.

## 5. The rule

Fill in the stub `src/<Pascal>Rule.php`, which `rules.neon` already registers: narrow `Node` in `@implements Rule<…>` and `getNodeType()` to the node the rule inspects, and write `processNode()`. Give every error an `->identifier('<category>.<name>')`, as a string literal so `check.sh` can find it, and, where it helps, a `->tip(...)`. Replace `__RULE_DOC__` with what it reports and what it deliberately leaves alone.

## 6. Check

1. Fill the README's `__WHAT_IT_REPORTS__` (with a short reported/preferred example) and `__IDENTIFIER__`. With several identifiers, name each in its own `@phpstan-ignore` example.
2. Run `check.sh <dir>` and fix what it reports until it prints `check: all passed`. It fails on unfilled placeholders, README identifiers that don't match the rule's, an invalid `composer.json`, failing tests, PHPStan errors, Pint issues, and any mutant Infection generates that the tests don't kill.
3. For each escaped or uncovered mutant, find the behaviour it breaks and add a test for it. Only when a mutant can't change behaviour, ignore it in `infection.json5`, keeping `"@default": true` so the other mutators still run, with a comment saying why:

   ```json5
   "mutators": {
       "@default": true,
       // Without the early return the loop below finds no promoted parameters either
       "ReturnRemoval": {"ignore": ["<rule namespace>\\<Pascal>Rule::inferredTargets"]}
   }
   ```

## 7. Commit and tag

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/release.sh" <dir>
```

It runs `check.sh`, commits everything as `Add <Pascal>Rule` with the description as its body, and tags `v0.1.0`.

## 8. Publish

Only if the user asked to publish. Otherwise stop here and offer it.

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/publish.sh" <dir>
```

It creates the GitHub repo `phpstan-<name>`, pushes, and submits the package to Packagist. Each step is skipped when already done, so after a failure fix the cause and run it again. If it says `github` or `packagist` isn't on the PATH, or reports missing credentials, point the user to the setup in [repo-tools' README](https://github.com/ianflanagan1/repo-tools#setup); don't look for the commands elsewhere, and never try to log in or read tokens yourself.

## 9. Use it

If the user wanted the rule for a particular project, offer to require it there: `composer require --dev ianflanagan1/phpstan-<name> phpstan/extension-installer` (allowing `phpstan/extension-installer` under `config.allow-plugins`), then run that project's PHPStan and report what the rule finds.

## Report

Start with one status line:

- `✅ Created ianflanagan1/phpstan-<name>.` once it's committed and tagged, or `✅ Published ianflanagan1/phpstan-<name>.` once it's on Packagist. Then name the behaviours tested, give the GitHub and Packagist URLs if published, and say what's left for the user to do.
- `⚠️ Can't scaffold <name>.` when `scaffold.sh` stopped before creating anything, then its reason.
- `⚠️ repo-tools isn't set up.` when `publish.sh` can't find `github` or `packagist`, then the setup link.
- `🛑 Stopped.` when a script failed after changing state (the package directory exists, or the GitHub repo was created but Packagist failed), then what was done, what's left, and the command to resume.
- `❌ Publish failed.` when `publish.sh` failed before publishing anything, then its error unchanged in a fenced `text` block and one line on the cause.
