#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eipd01.yml
kubectl apply -f 00-eipd02.yml 
kubectl apply -f 00-eip-first-static.yaml
#  show
sleep 5

#  show
kubectl get eip --show-labels

# create nat

kubectl apply -f 03-dnat01.yaml
kubectl apply -f 03-dnat02.yaml


sleep 5
kubectl get dnat --show-labels



# fip change eip

kubectl apply -f 03-dnat01-change-eip.yaml

sleep 5
kubectl get dnat --show-labels



# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5


#  show
kubectl get eip --show-labels
kubectl get dnat --show-labels
