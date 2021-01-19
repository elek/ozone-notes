#!/usr/bin/env bash
set -ex

export K8S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$K8S_DIR"
mkdir -p results

# shellcheck source=/dev/null
source "../testlib.sh"

reset_k8s_env

flekszible generate

kubectl apply -f ozone
kubectl apply -f hdfs

retry grep_log ozone-scm-0 "SCM exiting safe mode."
retry grep_log ozone-om-0 "HTTP server of ozoneManager listening"
retry grep_log hdfs-namenode-0 "Adding new storage ID"

kubectl exec ozone-scm-0 -- ozone sh volume create /vol1
kubectl exec ozone-scm-0 -- ozone sh bucket create /vol1/bucket1
kubectl exec ozone-scm-0 -- ozone sh key put /vol1/bucket1/key1 README.md

kubectl exec -it hdfs-namenode-0 -- hdfs dfs -chmod 777 hdfs://hdfs-namenode-0.hdfs-namenode:9820/

kubectl apply -f .
