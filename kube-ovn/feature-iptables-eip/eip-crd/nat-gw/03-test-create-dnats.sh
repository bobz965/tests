#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eipd01.yml 
sleep 2
kubectl apply -f 00-eipd02.yml
sleep 2
kubectl apply -f 00-eip-static.yaml
sleep 2


# create nat

kubectl apply -f 03-dnat01.yaml
sleep 2
kubectl apply -f 03-dnat02.yaml
sleep 2


#  show
kubectl get eip
kubectl get dnat
