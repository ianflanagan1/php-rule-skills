---
name: ianf-new-rector-rule
description: Create a new custom Rector rule as its own Composer package (ianflanagan1/rector-<name>), test-first, and optionally publish it to GitHub and Packagist. Use when the user wants a Rector rule that rewrites code to a convention, especially one to reuse across projects.
argument-hint: <what the rule should change>
disable-model-invocation: true
model: inherit
allowed-tools: Bash(bash *scripts/scaffold.sh*), Bash(bash *scripts/check.sh*), Bash(bash *scripts/release.sh*), Bash(bash *scripts/publish.sh*)
---

# New Rector rule

Build one Rector rule as its own package in `~/projects/php/rector-rules/<name>/`, from the template next to this file. The scripts in `scripts/` do the mechanical steps; you do the parts that need judgement. Run them as `bash "${CLAUDE_SKILL_DIR}/scripts/<script>.sh" …`.

## 1. Settle the name and description

- **Name:** kebab-case, naming the change the rule makes, e.g. `yield-data-provider`. It becomes the package `ianflanagan1/rector-<name>` and the class `<PascalName>Rector`, and the package name is permanent once on Packagist. Unless the user gave one, propose one or two and wait for their choice.
- **Description:** one sentence, starting "A Rector rule that …". It also becomes the body of the package's first commit.

## 2. Find out what Rector actually does

Before encoding an assumption about the code the rule rewrites, probe it: which php-parser nodes the code parses into, what types `$this->getType($node)` gives, and how Rector prints the result. Do it in the scaffolded package (step 3) with a scratch fixture: dump the node in `refactor()` with `(new \PhpParser\NodeDumper())->dump($node)`, run the test, read the output, then remove the dump and the fixture. Check that the code the rule will produce is what a person would write, comments and formatting included, and that it still means the same thing. Note which cases the probes settled; they become fixtures.

## 3. Scaffold

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/scaffold.sh" <name> "<description>"
```

It creates the package (with its own git repo) with stubs for the rule and its test, installs dev dependencies with Docker, and prints the class, namespace and what's left to fill. It stops if the directory exists, the name is taken on Packagist or Docker isn't running.

## 4. Tests first

The test, `tests/<Pascal>RectorTest.php`, runs every fixture in `tests/Fixture/` through the rule, as `tests/config/configured_rule.php` registers it, and also runs each code sample in the rule's `getRuleDefinition()`, so the documentation can't drift from what the rule does. Leave it as it is and add fixtures:

- One `.php.inc` fixture per behaviour, named for it: `a_data_provider_returning_an_array_yields_each_item.php.inc`.
- A fixture holds the code before the rule, a line `-----`, then the code the rule should produce. Without a `-----` line it holds code the rule must leave unchanged; name those for why, e.g. `a_provider_reused_by_another_method_is_left_alone.php.inc`.
- Give each fixture namespace `<rule namespace>\Tests\Fixture`, and end each half with `?>` as Rector's own fixtures do.
- Cover what must change **and** what must not: near-misses, other syntax for the same thing, closures, traits, comments next to the changed code.

Run `check.sh <dir>` and see the tests fail before writing the rule.

## 5. The rule

Fill in the stub `src/<Pascal>Rector.php`: list the node classes the rule inspects in `getNodeTypes()`, narrow `refactor()`'s `@param` to them, and write `refactor()`. It returns the changed node, or `null` to leave the node alone. Get Rector's services, such as `PhpDocInfoFactory`, through the constructor; Rector autowires them. Fill `getRuleDefinition()`: `__SUMMARY__` with one sentence on what it changes, and `__BEFORE__` and `__AFTER__` with a short example, every line indented to the `CODE_SAMPLE` marker below it, as PHP's heredoc requires. Replace `__RULE_DOC__` with what it changes and what it deliberately leaves alone.

## 6. Check

1. Fill the README's `__WHAT_IT_CHANGES__` with the same before/after example and the cases it leaves alone.
2. Run `check.sh <dir>` and fix what it reports until it prints `check: all passed`. It fails on unfilled placeholders, a file in `tests/Fixture/` that isn't `.php.inc` (the test would skip it), no fixture the rule changes or none it leaves alone, an invalid `composer.json`, failing tests, PHPStan errors, Pint issues, and any mutant Infection generates that the tests don't kill.
3. For each escaped or uncovered mutant, find the behaviour it breaks and add a fixture for it. Only when a mutant can't change behaviour, ignore it in `infection.json5`, keeping `"@default": true` so the other mutators still run, with a comment saying why:

   ```json5
   "mutators": {
       "@default": true,
       // Rector calls refactor() only with the node types getNodeTypes() lists, so the guard is never false
       "InstanceOf_": {"ignore": ["<rule namespace>\\<Pascal>Rector::refactor"]}
   }
   ```

## 7. Commit and tag

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/release.sh" <dir>
```

It runs `check.sh`, commits everything as `Add <Pascal>Rector` with the description as its body, and tags `v0.1.0`.

## 8. Publish

Only if the user asked to publish. Otherwise stop here and offer it.

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/publish.sh" <dir>
```

It creates the GitHub repo `rector-<name>`, pushes, and submits the package to Packagist. Each step is skipped when already done, so after a failure fix the cause and run it again. If it says `github` or `packagist` isn't on the PATH, or reports missing credentials, point the user to the setup in [repo-tools' README](https://github.com/ianflanagan1/repo-tools#setup); don't look for the commands elsewhere, and never try to log in or read tokens yourself.

## 9. Use it

If the user wanted the rule for a particular project, offer to add it there: `composer require --dev ianflanagan1/rector-<name>`, add `<rule namespace>\<Pascal>Rector::class` to `withRules()` in its `rector.php`, then run that project's Rector with `--dry-run` and report what the rule would change.

## Report

Start with one status line:

- `✅ Created ianflanagan1/rector-<name>.` once it's committed and tagged, or `✅ Published ianflanagan1/rector-<name>.` once it's on Packagist. Then name the behaviours the fixtures cover, give the GitHub and Packagist URLs if published, and say what's left for the user to do.
- `⚠️ Can't scaffold <name>.` when `scaffold.sh` stopped before creating anything, then its reason.
- `⚠️ repo-tools isn't set up.` when `publish.sh` can't find `github` or `packagist`, then the setup link.
- `🛑 Stopped.` when a script failed after changing state (the package directory exists, or the GitHub repo was created but Packagist failed), then what was done, what's left, and the command to resume.
- `❌ Publish failed.` when `publish.sh` failed before publishing anything, then its error unchanged in a fenced `text` block and one line on the cause.
