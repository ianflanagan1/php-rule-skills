# rector-__NAME__

__DESCRIPTION__

## Installation

```sh
composer require --dev __PACKAGE__
```

Then add the rule to your `rector.php`:

```php
use __NAMESPACE__\__PASCAL__Rector;

return RectorConfig::configure()
    ->withRules([__PASCAL__Rector::class]);
```

Requires PHP 8.3+ and Rector 2.8+.

## What it changes

__WHAT_IT_CHANGES__

To leave a file alone, skip the rule for it in `rector.php`: `->withSkip([__PASCAL__Rector::class => ['path/to/File.php']])`.

## Development

```sh
composer install
vendor/bin/phpunit
vendor/bin/phpstan analyse
vendor/bin/pint --test
vendor/bin/infection --with-uncovered --show-mutations=0
```

The test in `tests/` is built on Rector's `AbstractRectorTestCase` and runs every fixture in `tests/Fixture/`. Each is a `.php.inc` file holding code before the rule, then a `-----` line and the code the rule should produce; a fixture without a `-----` line holds code the rule must leave unchanged. Infection needs a coverage driver such as pcov, and fails unless the tests kill every mutant.

## License

MIT
