#!/usr/bin/env bash
set -ex

export K8S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$K8S_DIR"
mkdir -p results

# shellcheck source=/dev/null
source "testlib.sh"

reset_k8s_env

kubectl apply -f ozone-config-configmap.yaml
kubectl apply -f ozone-datanode-statefulset.yaml
kubectl apply -f ozone-datanode-service.yaml

retry grep_log ozone-datanode-0 "Starting XceiverServerRatis"

RAFT_ID=$(kubectl logs ozone-datanode-0 | grep "Starting XceiverServerRatis" | awk '{print $8}')

sed -i "s/-r .*/-r $RAFT_ID/" configmaps/ozone-testscript_test.sh

flekszible generate

kubectl apply -f ozone-testscript-configmap.yaml
kubectl apply -f ozone-env-deployment.yaml

kubectl wait --timeout=300s pod --for=condition=Ready -l app=ozone,component=env

TEST_POD=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l component=env)

MAX_RETRY=100 retry grep_log $TEST_POD "Test is Done"

kubectl logs --tail=20 $TEST_POD | tee results/result.txt
