# php-rule-skills

Claude Code skills that create a custom PHP rule as its own Composer package, test-first, and optionally publish it to GitHub and Packagist. `/ianf-new-phpstan-rule` makes a PHPStan rule, which reports code that breaks a convention; `/ianf-new-rector-rule` makes a Rector rule, which rewrites code to follow one; `/ianf-new-php-cs-fixer-rule` makes a PHP-CS-Fixer rule, which reformats code to follow one.

## Why

A convention that's only written down gets broken; a PHPStan, Rector or PHP-CS-Fixer rule enforces it in every project that installs it. Making each rule its own package lets a project install just the rules it wants, and version them separately. The cost is the same setup every time, which these skills make deterministic.

## What it does

`/ianf-new-phpstan-rule <what the rule should report>`:

1. Settles a package name with you. It's permanent once on Packagist.
2. Probes PHPStan's actual behaviour before encoding any assumption about it.
3. Scaffolds the package with `scripts/scaffold.sh` from `template/`: stubs for the rule and its test, Composer, PHPUnit, PHPStan, Pint, Infection and CI config, licence and README.
4. Writes behaviour-named `RuleTestCase` tests with one fixture each and sees them fail.
5. Writes the rule, then runs `scripts/check.sh` until everything passes, including Infection with every mutant killed.
6. Commits and tags `v0.1.0` with `scripts/release.sh`.
7. If you asked, publishes with `scripts/publish.sh`, which runs the `github` and `packagist` commands from [repo-tools](https://github.com/ianflanagan1/repo-tools), found on your PATH.
8. Offers to require the package in the project that needed it.

Each package is created in `~/projects/php/phpstan-rules/<name>/` as an independent git repo. Set `PHPSTAN_RULES_DIR` to use another directory.

| | Example |
|---|---|
| Directory | `inferable-var-tag-name` |
| Package and GitHub repo | `ianflanagan1/phpstan-inferable-var-tag-name` |
| Namespace | `IanFlanagan\PhpstanRules\InferableVarTagName` |
| Rule class | `InferableVarTagNameRule` |

`/ianf-new-rector-rule <what the rule should change>` follows the same steps, with Rector's `AbstractRectorTestCase` in step 4: one `.php.inc` fixture per behaviour in `tests/Fixture/`, holding the code before and after the rule, or only the code it must leave alone. Each package is created in `~/projects/php/rector-rules/<name>/`; set `RECTOR_RULES_DIR` to use another directory.

| | Example |
|---|---|
| Directory | `yield-data-provider` |
| Package and GitHub repo | `ianflanagan1/rector-yield-data-provider` |
| Namespace | `IanFlanagan\RectorRules\YieldDataProvider` |
| Rule class | `YieldDataProviderRector` |

`/ianf-new-php-cs-fixer-rule <what the rule should change>` uses the same kind of fixtures in `tests/Fixture/`, run through the fixer with PHP-CS-Fixer's `Tokens`, then fixed again to check the result is stable. The template's test also checks that the README allows risky rules exactly when the fixer is risky. Each package is created in `~/projects/php/php-cs-fixer-rules/<name>/`; set `PHP_CS_FIXER_RULES_DIR` to use another directory.

| | Example |
|---|---|
| Directory | `die-to-exit` |
| Package and GitHub repo | `ianflanagan1/php-cs-fixer-die-to-exit` |
| Namespace | `IanFlanagan\PhpCsFixerRules\DieToExit` |
| Rule class | `DieToExitFixer` |
| Rule name in configs | `IanFlanagan/die_to_exit` |

## Setup

1. Docker must be running: Composer and the checks run in an image built from `shared/docker/Dockerfile` (the `composer` image plus pcov, for Infection's coverage), so you don't need PHP installed. The first run builds it; Docker caches it after that.
2. Link the skills into Claude Code:

   ```sh
   ln -s ~/projects/claude/php-rule-skills/skills/ianf-new-phpstan-rule ~/.claude/skills/ianf-new-phpstan-rule
   ln -s ~/projects/claude/php-rule-skills/skills/ianf-new-rector-rule ~/.claude/skills/ianf-new-rector-rule
   ln -s ~/projects/claude/php-rule-skills/skills/ianf-new-php-cs-fixer-rule ~/.claude/skills/ianf-new-php-cs-fixer-rule
   ```

3. To publish, set up [repo-tools](https://github.com/ianflanagan1/repo-tools#setup) by following its README: `github` and `packagist` on your PATH, the GitHub token and the Packagist tokens.

To change the vendor, edit `VENDOR` in `shared/scripts/scaffold.sh`; for the author, `shared/template/LICENSE` and each skill's `template/composer.json`; for a skill's namespace, its `scripts/rule-kind.sh`; for the `IanFlanagan/` that starts each PHP-CS-Fixer rule name, that skill's fixer stub and README.

## The scripts

```sh
scripts/scaffold.sh <name> "<description>"   # new package from the template
scripts/check.sh <package-dir>               # placeholders, the rule kind's checks, composer validate, PHPUnit, PHPStan, Pint, Infection
scripts/release.sh <package-dir>             # check, first commit, tag v0.1.0
scripts/publish.sh <package-dir>             # GitHub repo and Packagist
```

Each skill's `allowed-tools` allows all four, so Claude runs them without asking. `scripts/lib.sh` holds what they share.

Template dotfiles are stored as `_gitignore`, `_gitattributes` and `_github/`, so they don't act on this repo, and the stubs with `__PASCAL__` in their names; `scaffold.sh` renames them.

## Shared files

What more than one kind of rule needs lives once in `shared/`: the scripts, the Docker image, and the template files that don't depend on the tool (licence, dotfiles, PHPUnit, Pint, Infection and CI config, and the PHPStan config the Rector and PHP-CS-Fixer packages share). Each skill links to them from its own `scripts/`, `docker` and `template/`, and keeps beside them what's specific to its kind of rule:

- `scripts/rule-kind.sh`, which `lib.sh` sources: the package prefix, namespace root, packages directory, class suffix, fixture directory and the placeholders left for Claude, plus `scaffold_todo` and `rule_kind_checks`, the checks only that kind needs (for PHPStan, that the README documents exactly the rule's error identifiers; for Rector and PHP-CS-Fixer, `lib.sh`'s `check_before_after_fixtures`: every fixture is a `.php.inc` file and there's at least one the rule changes and one it leaves alone).
- the rest of `template/`: `composer.json`, the README, the stubs, and the PHPStan config where it's the tool's own.

`scaffold.sh` copies the template with its links followed. To vendor a skill, copy it with `cp -RL` so the links become real files.

## Development

```sh
devbox run -- task check   # shellcheck and the tests
devbox run -- task test    # just the shunit2 tests, or the files given after --
```

The tests in `tests/` run the scripts through the skill's folder, as they're installed, with stub `docker`, `curl`, `github` and `packagist` commands, so they need no Docker, network or credentials.

## License

MIT
