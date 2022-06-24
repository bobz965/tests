#!/usr/bin/env bash
set -euo pipefail

# create vip
echo "show vip before test"
kubectl get vip

kubectl apply -f 00-vipd01.yaml
sleep 2 
kubectl apply -f 00-pod-with-vip.yaml
sleep 2 

ip=`kubectl get vip vip-dynamic-01 -o jsonpath='{.spec.v4ip}'`
echo "vip v4ip, $ip"


kubectl get vip vip-dynamic-01 -o yaml| grep -A 5 '  labels:'

kubectl get pod -n default static-ip -o wide | grep "$ip"

kubectl get ip  static-ip.default | grep "$ip"

echo "done"
