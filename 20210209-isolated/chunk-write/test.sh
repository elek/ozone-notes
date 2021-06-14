#!/usr/bin/env bash
set -ex

export K8S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$K8S_DIR"

mkdir -p results
# shellcheck source=/dev/null

source "../testlib.sh"

reset_k8s_env

flekszible generate

kubectl apply -f .

retry grep_log ozone-scm-0 "SCM exiting safe mode."
retry grep_log ozone-om-0 "HTTP server of ozoneManager listening"

kubectl apply -f freon

retry grep_pod_list freon

kubectl wait pod --timeout=300s --for=condition=Ready -l app=ozone,component=freon

TEST_POD=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' -l component=freon)

MAX_RETRY=100 retry grep_log $TEST_POD "Successful executions"

kubectl logs --tail=20 $TEST_POD | tee results/result.txt
