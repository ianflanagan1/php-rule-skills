<?php

declare(strict_types=1);

namespace __NAMESPACE__\Tests;

use __NAMESPACE__\__PASCAL__Rector;
use Iterator;
use Override;
use PHPUnit\Framework\Attributes\DataProvider;
use Rector\Testing\PHPUnit\AbstractRectorTestCase;

/**
 * Runs every fixture in Fixture/, each named for the behaviour it shows. A fixture holds code
 * before the rule, then a ----- line and the code the rule should produce; one without a -----
 * line holds code the rule must leave unchanged.
 */
final class __PASCAL__RectorTest extends AbstractRectorTestCase
{
    /**
     * @return Iterator<array-key, array{string}>
     */
    public static function fixtures(): Iterator
    {
        return self::yieldFilesFromDirectory(__DIR__ . '/Fixture');
    }

    #[DataProvider('fixtures')]
    public function test_the_rule_turns_each_fixture_into_its_expected_code(string $fixture): void
    {
        $this->doTestFile($fixture);
    }

    public function test_the_rules_code_samples_show_what_it_does(): void
    {
        $codeSamples = $this->make(__PASCAL__Rector::class)->getRuleDefinition()->getCodeSamples();
        $this->assertNotEmpty($codeSamples);

        foreach ($codeSamples as $codeSample) {
            $fixture = sys_get_temp_dir() . '/' . uniqid('code-sample-', true) . '.php.inc';
            file_put_contents($fixture, "<?php\n\n{$codeSample->getBadCode()}\n\n?>\n-----\n<?php\n\n{$codeSample->getGoodCode()}\n\n?>\n");

            try {
                $this->doTestFile($fixture);
            } finally {
                unlink($fixture);
            }
        }
    }

    #[Override]
    public function provideConfigFilePath(): string
    {
        return __DIR__ . '/config/configured_rule.php';
    }
}
