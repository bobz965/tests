#!/usr/bin/env bash
set -euo pipefail

# create eip
kubectl apply -f 00-eipd01.yml 
sleep 5
kubectl apply -f 00-eip-first-dynamic.yaml
sleep 5
kubectl apply -f 00-eip-first-static.yaml
sleep 5
kubectl get eip | grep 172.20.10.111



#  show
kubectl get eip

# change eip 
kubectl apply -f  00-eip-first-dynamic-01-then-static.yaml
sleep 5

kubectl get eip | grep 172.20.10.200

kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5
kubectl get eip | grep 172.20.10.222

#  show
kubectl get eip
