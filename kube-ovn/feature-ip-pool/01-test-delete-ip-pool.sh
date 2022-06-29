#!/usr/bin/env bash
set -euo pipefail

# delete ip pool
echo "show ip pool before test"
kubectl get ippl
kubectl delete -f 01-ip-pool.yaml
sleep 2 
kubectl get vip
echo "done"
