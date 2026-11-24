<?php

declare(strict_types=1);

namespace __NAMESPACE__;

use Override;
use PhpCsFixer\Fixer\FixerInterface;
use PhpCsFixer\FixerDefinition\CodeSample;
use PhpCsFixer\FixerDefinition\FixerDefinition;
use PhpCsFixer\FixerDefinition\FixerDefinitionInterface;
use PhpCsFixer\Tokenizer\Tokens;
use SplFileInfo;

/**
 * __RULE_DOC__
 */
final readonly class __PASCAL__Fixer implements FixerInterface
{
    #[Override]
    public function getName(): string
    {
        return 'IanFlanagan/__SNAKE__';
    }

    #[Override]
    public function getDefinition(): FixerDefinitionInterface
    {
        return new FixerDefinition('__SUMMARY__', [
            new CodeSample(
                <<<'PHP'
                    <?php

                    __SAMPLE__

                    PHP,
            ),
        ]);
    }

    #[Override]
    public function isRisky(): bool
    {
        return false;
    }

    #[Override]
    public function getPriority(): int
    {
        return 0;
    }

    #[Override]
    public function supports(SplFileInfo $file): bool
    {
        return true;
    }

    #[Override]
    public function isCandidate(Tokens $tokens): bool
    {
        return true;
    }

    #[Override]
    public function fix(SplFileInfo $file, Tokens $tokens): void
    {
    }
}
