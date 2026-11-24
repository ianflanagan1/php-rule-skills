<?php

declare(strict_types=1);

namespace __NAMESPACE__;

use Override;
use PhpParser\Node;
use Rector\Rector\AbstractRector;
use Rector\RuleDoc\CodeSample\CodeSample;
use Rector\RuleDoc\Contract\DocumentedRuleInterface;
use Rector\RuleDoc\RuleDefinition;

/**
 * __RULE_DOC__
 */
final class __PASCAL__Rector extends AbstractRector implements DocumentedRuleInterface
{
    #[Override]
    public function getRuleDefinition(): RuleDefinition
    {
        return new RuleDefinition('__SUMMARY__', [
            new CodeSample(
                <<<'CODE_SAMPLE'
                    __BEFORE__
                    CODE_SAMPLE,
                <<<'CODE_SAMPLE'
                    __AFTER__
                    CODE_SAMPLE,
            ),
        ]);
    }

    /**
     * @return array<class-string<Node>>
     */
    #[Override]
    public function getNodeTypes(): array
    {
        return [Node::class];
    }

    #[Override]
    public function refactor(Node $node): ?Node
    {
        return null;
    }
}
