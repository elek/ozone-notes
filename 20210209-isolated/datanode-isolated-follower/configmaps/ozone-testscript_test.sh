#!/usr/bin/env bash
set -ex
time sync
START_TIME=$(date +%s.%N)
ozone freon --verbose falg -n200000 --open-containers 48 --batching 48 -s 4194304 -c ozone-datanode-0.ozone-datanode:9856 -a ozone-datanode-0.ozone-datanode:9857 -t1 -r deca1f9d-80e9-4a7a-bca0-31b3f2029903
time sync
END_TIME=$(date +%s.%N)
echo "Total time: $(echo $END_TIME $START_TIME | awk '{print $1 - $2}')"
echo "Test is Done"
sleep 100000
