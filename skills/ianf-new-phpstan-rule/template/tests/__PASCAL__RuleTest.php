<?php

declare(strict_types=1);

namespace __NAMESPACE__\Tests;

use __NAMESPACE__\__PASCAL__Rule;
use Override;
use PHPStan\Rules\Rule;
use PHPStan\Testing\RuleTestCase;

/**
 * @extends RuleTestCase<__PASCAL__Rule>
 */
final class __PASCAL__RuleTest extends RuleTestCase
{
    #[Override]
    protected function getRule(): Rule
    {
        return new __PASCAL__Rule();
    }
}
