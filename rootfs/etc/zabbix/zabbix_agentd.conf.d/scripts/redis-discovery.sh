#!/usr/bin/env bash
# Author:   Lesovsky A.V.
# Description:  Get values stored in Redis keys

getValues=$(redis-cli${REDIS_PASS:+ -a "${REDIS_PASS}"} --raw $1 $2)

echo -n '{"data":['
    or value in $getValues; do echo -n "{\"{#VALUE}\": \"$value\"},"; done |sed -e 's:\},$:\}:'
echo -n ']}'

