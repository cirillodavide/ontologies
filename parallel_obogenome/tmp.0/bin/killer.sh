#!/bin/sh

file=$1
while [ 1 ]; do
    perl bin/killer.pl $file
    sleep 5
done
