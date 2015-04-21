#!/bin/bash

TAGFILE=/tmp/guardian-test-numbers
for((i=1;i<=`wc -l $TAGFILE | sed s/'[ ][ ][ ]*'//g | cut -f 1 -d ' '`;i++));
do
    head -n $i $TAGFILE | tail -n 1
done
cat -
