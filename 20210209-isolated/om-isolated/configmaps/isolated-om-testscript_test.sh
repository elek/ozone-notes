#!/usr/bin/env bash
set -x
sleep 10
time sync
START_TIME=$(date +%s.%N)
ozone freon --verbose omkg -n1000000000
time sync
END_TIME=$(date +%s.%N)
echo "Total time: $(echo $END_TIME $START_TIME | awk '{print $1 - $2}')"
sleep 100000
