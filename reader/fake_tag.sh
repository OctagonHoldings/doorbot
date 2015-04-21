#!/bin/bash

TAGFILE=`dirname $0`/test.tags
for((i=1;i<=`wc -l $TAGFILE | sed s/'[ ][ ][ ]*'//g | cut -f 1 -d ' '`;i++));
do
    head -n $i $TAGFILE | tail -n 1
    sleep 1
done
cat -
