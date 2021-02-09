#!/usr/bin/env bash

set -ex

mkdir results || true
RESULT_FILE=results/result-$(date +%s).txt

flekszible generate

kubectl delete job --all
kubectl apply -f testscripts-configmap.yaml

flekszible generate --print \
    -t namefilter:include=test-runner \
    -t run:args="/opt/testscripts/parquet.sh $*" | kubectl apply -f -

echo $@ > $RESULT_FILE

stern test-runner &

kubectl wait --timeout=6000s -l job-name=test-runner --for=condition=complete job

pkill -f stern

kubectl logs --tail=-1 -l job-name=test-runner | tee -a $RESULT_FILE | grep "parquet at" | grep finished

