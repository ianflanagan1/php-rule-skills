<?php

declare(strict_types=1);

namespace __NAMESPACE__;

use Override;
use PhpParser\Node;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\Rule;

/**
 * __RULE_DOC__
 *
 * @implements Rule<Node>
 */
final readonly class __PASCAL__Rule implements Rule
{
    #[Override]
    public function getNodeType(): string
    {
        return Node::class;
    }

    #[Override]
    public function processNode(Node $node, Scope $scope): array
    {
        return [];
    }
}
