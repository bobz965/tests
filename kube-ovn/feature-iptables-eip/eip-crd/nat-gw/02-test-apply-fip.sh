#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eipf01.yml
kubectl apply -f 00-eipf02.yml 
kubectl apply -f 00-eip-first-static.yaml
#  show
sleep 5

#  show
kubectl get eip --show-labels
kubectl get fip --show-labels


# create nat

kubectl apply -f 02-fip-rule01.yaml
kubectl apply -f 02-fip-eip-static.yaml


sleep 5
kubectl get fip --show-labels



# fip change eip --show-labels

kubectl apply -f 02-fip-rule01-change-eip.yaml

sleep 5
kubectl get fip --show-labels



# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5

kubectl get fip --show-labels

#  show
kubectl get eip --show-labels
kubectl get fip --show-labels
