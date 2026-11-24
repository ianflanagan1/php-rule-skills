<?php

declare(strict_types=1);

namespace __NAMESPACE__\Tests;

use __NAMESPACE__\__PASCAL__Fixer;
use PhpCsFixer\Tokenizer\Tokens;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use SplFileInfo;

/**
 * Runs every fixture in Fixture/, each named for the behaviour it shows. A fixture holds code
 * before the fixer, then a ----- line and the code the fixer should produce; one without a -----
 * line holds code the fixer must leave unchanged.
 */
final class __PASCAL__FixerTest extends TestCase
{
    /**
     * @return iterable<string, array{string}>
     */
    public static function fixtures(): iterable
    {
        foreach (glob(__DIR__ . '/Fixture/*.php.inc') ?: [] as $fixture) {
            yield basename($fixture, '.php.inc') => [$fixture];
        }
    }

    #[DataProvider('fixtures')]
    public function test_the_fixer_turns_each_fixture_into_its_expected_code(string $fixture): void
    {
        $contents = (string) file_get_contents($fixture);
        $parts = explode("\n-----\n", $contents, 2);
        $input = count($parts) === 2
            ? $parts[0] . "\n"
            : $contents;
        $expected = $parts[1] ?? $contents;

        $this->assertSame($expected, $this->fix($input), 'The fixer should turn the code before ----- into the code after it');
        $this->assertSame($expected, $this->fix($expected), 'Fixing the result again should leave it unchanged');
    }

    public function test_the_fixers_code_samples_show_it_changing_code(): void
    {
        $fixer = new __PASCAL__Fixer();
        $codeSamples = $fixer->getDefinition()->getCodeSamples();
        $this->assertNotEmpty($codeSamples);

        foreach ($codeSamples as $codeSample) {
            $this->assertNotSame($codeSample->getCode(), $this->fix($codeSample->getCode()));
        }
    }

    public function test_the_fixers_name_is_one_php_cs_fixer_accepts_for_a_custom_fixer(): void
    {
        $fixer = new __PASCAL__Fixer();

        // The pattern PHP-CS-Fixer's FixerNameValidator, which is internal, applies to custom fixers
        $this->assertMatchesRegularExpression('/^[A-Z][a-zA-Z0-9]*\/[a-z][a-z0-9_]*$/', $fixer->getName());
    }

    public function test_the_readme_allows_risky_rules_exactly_when_the_fixer_is_risky(): void
    {
        $fixer = new __PASCAL__Fixer();
        $readme = (string) file_get_contents(__DIR__ . '/../README.md');

        // PHP-CS-Fixer refuses to run a risky fixer unless the config allows risky rules
        $this->assertSame($fixer->isRisky(), str_contains($readme, '->setRiskyAllowed(true)'));
    }

    /**
     * Fixes code as PHP-CS-Fixer's runner does, and fails if the result isn't valid PHP.
     */
    private function fix(string $code): string
    {
        $fixer = new __PASCAL__Fixer();
        $file = new SplFileInfo(__FILE__);

        // Tokens caches each collection by its code, so a fixed one would be reused
        Tokens::clearCache();
        $tokens = Tokens::fromCode($code);
        if ($fixer->supports($file) && $fixer->isCandidate($tokens)) {
            $fixer->fix($file, $tokens);
        }
        $fixed = $tokens->generateCode();

        // Tokenizing parses the code, so this throws a ParseError if the fixer broke it
        Tokens::clearCache();
        Tokens::fromCode($fixed);

        return $fixed;
    }
}
