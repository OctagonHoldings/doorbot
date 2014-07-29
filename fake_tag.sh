#!/bin/bash

for((i=1;i<=`wc -l test.tags | sed s/'[ ][ ][ ]*'//g | cut -f 1 -d ' '`;i++));
do
    head -n $i test.tags | tail -n 1
    sleep 1
done
cat -
