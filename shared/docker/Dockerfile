# The composer image with pcov, which Infection needs for coverage: PHPUnit 12 can't collect
# it through phpdbg. Built and tagged by scripts/lib.sh; Docker caches it after the first build.
FROM composer:latest

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install pcov \
    && docker-php-ext-enable pcov \
    && apk del .build-deps
