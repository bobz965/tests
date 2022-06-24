#!/usr/bin/env bash
set -euo pipefail

# delete vip
echo "show vip before test"
kubectl get vip
kubectl delete -f 00-pod-with-vip.yaml
sleep 2 
kubectl delete -f 00-vipd01.yaml
sleep 2 
echo "done"
