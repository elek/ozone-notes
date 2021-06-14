#!/usr/bin/env bash
kubectl delete -f .
kubectl wait pod --for=delete -l component=om-isolated
kubectl wait configmap --for=delete ozone-config
kubectl wait configmap --for=delete isolated-om-testscript
flekszible generate
kubectl apply -f .
