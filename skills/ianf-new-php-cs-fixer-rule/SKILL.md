---
name: ianf-new-php-cs-fixer-rule
description: Create a new custom PHP-CS-Fixer rule (a fixer) as its own Composer package (ianflanagan1/php-cs-fixer-<name>), test-first, and optionally publish it to GitHub and Packagist. Use when the user wants a PHP-CS-Fixer rule that reformats code to a convention, especially one to reuse across projects.
argument-hint: <what the rule should change>
disable-model-invocation: true
model: inherit
allowed-tools: Bash(bash *scripts/scaffold.sh*), Bash(bash *scripts/check.sh*), Bash(bash *scripts/release.sh*), Bash(bash *scripts/publish.sh*)
---

# New PHP-CS-Fixer rule

Build one PHP-CS-Fixer rule as its own package in `~/projects/php/php-cs-fixer-rules/<name>/`, from the template next to this file. The scripts in `scripts/` do the mechanical steps; you do the parts that need judgement. Run them as `bash "${CLAUDE_SKILL_DIR}/scripts/<script>.sh" …`.

## 1. Settle the name and description

- **Name:** kebab-case, naming the change the rule makes, e.g. `die-to-exit`. It becomes the package `ianflanagan1/php-cs-fixer-<name>`, the class `<PascalName>Fixer` and the rule `IanFlanagan/<snake_name>` that configs turn on, and the package name is permanent once on Packagist. Unless the user gave one, propose one or two and wait for their choice.
- **Description:** one sentence, starting "A PHP-CS-Fixer rule that …". It also becomes the body of the package's first commit.

## 2. Find out what PHP-CS-Fixer actually does

Before encoding an assumption about the code the rule rewrites, probe it: which tokens the code is made of, and which built-in fixers touch the same code. Do it in the scaffolded package (step 3) with a scratch fixture: in `fix()`, print each token with `fwrite(STDERR, $index . ' ' . ($token->getName() ?? '') . ' ' . json_encode($token->getContent()) . "\n")`, run the test, read the output, then remove the dump and the fixture. Look for the related built-in fixers in `vendor/friendsofphp/php-cs-fixer/src/Fixer/`; the docblock on each one's `getPriority()` says which fixers it must run before and after. Check that the code the rule will produce is what a person would write, and that it still means the same thing. If it can change what the code does, the rule is risky. Note which cases the probes settled; they become fixtures.

## 3. Scaffold

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/scaffold.sh" <name> "<description>"
```

It creates the package (with its own git repo) with stubs for the fixer and its test, installs dev dependencies with Docker, and prints the class, namespace and what's left to fill. It stops if the directory exists, the name is taken on Packagist or Docker isn't running.

## 4. Tests first

The test, `tests/<Pascal>FixerTest.php`, runs every fixture in `tests/Fixture/` through the fixer as PHP-CS-Fixer's runner does (`supports()`, then `isCandidate()`, then `fix()`), fixes the result again to check it's left unchanged, and fails if the result isn't valid PHP. It also checks that each code sample in `getDefinition()` is changed by the fixer, that the fixer's name is one PHP-CS-Fixer accepts, and that the README allows risky rules exactly when the fixer is risky. Leave it as it is and add fixtures:

- One `.php.inc` fixture per behaviour, named for it: `die_in_capitals_becomes_exit.php.inc`.
- A fixture holds the code before the fixer, a line `-----`, then the code the fixer should produce, both exactly as in a file: starting `<?php` and ending with a newline. Without a `-----` line it holds code the fixer must leave unchanged; name those for why, e.g. `a_method_named_die_is_left_alone.php.inc`.
- A fixture the fixer must leave unchanged tests `fix()` only if `isCandidate()` accepts it, so give it a token `isCandidate()` looks for, such as an `exit(1);` beside the `$process->die();` that must not change.
- Cover what must change **and** what must not: near-misses, other syntax for the same thing, other letter cases, comments and whitespace next to the changed code.

Run `check.sh <dir>` and see the tests fail before writing the fixer.

## 5. The fixer

Fill in the stub `src/<Pascal>Fixer.php`:

- `isCandidate()`: whether the file has the tokens the fixer looks for, e.g. `$tokens->isTokenKindFound(T_EXIT)`. It saves the runner work, so keep it cheap.
- `fix()`: change `$tokens` in place, through the public methods of `Tokens` and `Token` and the token kinds in `CT`. Don't use PHP-CS-Fixer's `@internal` classes (`AbstractFixer`, `TokensAnalyzer`, the `Tokenizer\Analyzer` classes, `FixerFactory`), which can change in any release. PHPStan doesn't report them. If the fixer inserts line breaks or indentation, implement `WhitespacesAwareFixerInterface` and use the whitespace it's given, which needs the class not to be `readonly`.
- `isRisky()`: `true` if the change can alter what the code does. Then add `->setRiskyAllowed(true)` to the README's config and say there why it's risky.
- `getPriority()`: higher runs earlier. Where step 2 found fixers this one must run before or after, choose a value between theirs and say so in the docblock as PHP-CS-Fixer does ("Must run before …. Must run after …."); otherwise leave it `0`.
- `getDefinition()`: fill `__SUMMARY__` with one sentence on what it changes, and `__SAMPLE__` with a short example of code it changes, every line indented to the `PHP` marker below it, as PHP's heredoc requires.
- Replace `__RULE_DOC__` with what it changes and what it deliberately leaves alone.

## 6. Check

1. Fill the README's `__WHAT_IT_CHANGES__` with a short before/after example and the cases it leaves alone.
2. Run `check.sh <dir>` and fix what it reports until it prints `check: all passed`. It fails on unfilled placeholders, a file in `tests/Fixture/` that isn't `.php.inc` (the test would skip it), no fixture the fixer changes or none it leaves alone, an invalid `composer.json`, failing tests, PHPStan errors, Pint issues, and any mutant Infection generates that the tests don't kill.
3. For each escaped or uncovered mutant, find the behaviour it breaks and add a fixture for it. A mutant of `getPriority()` breaks the order the fixer runs in: when step 5 placed it between other fixers, add a test asserting it runs before and after them, comparing with their `getPriority()`. Only when a mutant can't change behaviour, ignore it in `infection.json5`, keeping `"@default": true` so the other mutators still run, with a comment saying why:

   ```json5
   "mutators": {
       "@default": true,
       // Nothing constrains when this fixer runs: no other fixer changes die or exit
       "IncrementInteger": {"ignore": ["<rule namespace>\\<Pascal>Fixer::getPriority"]},
       "DecrementInteger": {"ignore": ["<rule namespace>\\<Pascal>Fixer::getPriority"]}
   }
   ```

## 7. Commit and tag

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/release.sh" <dir>
```

It runs `check.sh`, commits everything as `Add <Pascal>Fixer` with the description as its body, and tags `v0.1.0`.

## 8. Publish

Only if the user asked to publish. Otherwise stop here and offer it.

```sh
bash "${CLAUDE_SKILL_DIR}/scripts/publish.sh" <dir>
```

It creates the GitHub repo `php-cs-fixer-<name>`, pushes, and submits the package to Packagist. Each step is skipped when already done, so after a failure fix the cause and run it again. If it says `github` or `packagist` isn't on the PATH, or reports missing credentials, point the user to the setup in [repo-tools' README](https://github.com/ianflanagan1/repo-tools#setup); don't look for the commands elsewhere, and never try to log in or read tokens yourself.

## 9. Use it

If the user wanted the rule for a particular project, offer to add it there: `composer require --dev ianflanagan1/php-cs-fixer-<name>`, register the fixer and turn on `IanFlanagan/<snake_name>` in its `.php-cs-fixer.dist.php` as the package's README shows, then run `vendor/bin/php-cs-fixer fix --dry-run --diff` and report what the rule would change. Pint can't load custom fixers, so if the project formats with Pint, say so and offer a `.php-cs-fixer.dist.php` that turns on only this rule, run beside Pint.

## Report

Start with one status line:

- `✅ Created ianflanagan1/php-cs-fixer-<name>.` once it's committed and tagged, or `✅ Published ianflanagan1/php-cs-fixer-<name>.` once it's on Packagist. Then name the behaviours the fixtures cover, give the GitHub and Packagist URLs if published, and say what's left for the user to do.
- `⚠️ Can't scaffold <name>.` when `scaffold.sh` stopped before creating anything, then its reason.
- `⚠️ repo-tools isn't set up.` when `publish.sh` can't find `github` or `packagist`, then the setup link.
- `🛑 Stopped.` when a script failed after changing state (the package directory exists, or the GitHub repo was created but Packagist failed), then what was done, what's left, and the command to resume.
- `❌ Publish failed.` when `publish.sh` failed before publishing anything, then its error unchanged in a fenced `text` block and one line on the cause.
