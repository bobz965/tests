#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eips01.yml
sleep 2
kubectl apply -f 00-eips02.yml
sleep 2
kubectl apply -f 00-eip-first-static.yaml
#  show
sleep 2

#  show
kubectl get eip --show-labels

# create nat

kubectl apply -f 01-snat01.yaml
sleep 2
kubectl apply -f 01-snat02.yaml
sleep 2

kubectl get snat --show-labels

# fip change eip
kubectl apply -f 01-snat01-change-eip.yaml

sleep 5
kubectl get snat --show-labels



# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5

#  show
kubectl get eip --show-labels
kubectl get snat --show-labels


