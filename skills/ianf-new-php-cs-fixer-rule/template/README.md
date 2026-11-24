# php-cs-fixer-__NAME__

__DESCRIPTION__

## Installation

```sh
composer require --dev __PACKAGE__
```

Then register the fixer and turn on its rule in your `.php-cs-fixer.dist.php`:

```php
use __NAMESPACE__\__PASCAL__Fixer;
use PhpCsFixer\Config;

return (new Config())
    ->registerCustomFixers([new __PASCAL__Fixer()])
    ->setRules([
        'IanFlanagan/__SNAKE__' => true,
    ]);
```

Requires PHP 8.3+ and PHP-CS-Fixer 3.95+. Pint can't load custom fixers, so a project formatted with Pint runs PHP-CS-Fixer for this rule alongside it.

## What it changes

__WHAT_IT_CHANGES__

To leave a file alone, exclude it from your config's finder: `->setFinder(Finder::create()->in(__DIR__)->notPath('path/to/File.php'))`.

## Development

```sh
composer install
vendor/bin/phpunit
vendor/bin/phpstan analyse
vendor/bin/pint --test
vendor/bin/infection --with-uncovered --show-mutations=0
```

The test in `tests/` runs every fixture in `tests/Fixture/` through the fixer, then fixes the result again to check it's left unchanged. Each fixture is a `.php.inc` file holding code before the fixer, then a `-----` line and the code the fixer should produce; a fixture without a `-----` line holds code the fixer must leave unchanged. Infection needs a coverage driver such as pcov, and fails unless the tests kill every mutant.

## License

MIT
