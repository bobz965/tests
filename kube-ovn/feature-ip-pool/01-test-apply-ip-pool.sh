#!/usr/bin/env bash
set -euo pipefail

# create ip pool
echo "show ip pool before test"
kubectl get ippl
kubectl apply -f 01-ip-pool.yaml
sleep 5
kubectl get ippl
kubectl get vip | grep ip-pool-dynamic
sleep 5
kubectl apply -f 01-ip-pool-increase.yaml
sleep 5
kubectl get ippl
kubectl get vip | grep ip-pool-dynamic
kubectl get vip ip-pool-dynamic-1 -o yaml| grep -A 5 '  labels:'
kubectl get ippl
echo "done"
