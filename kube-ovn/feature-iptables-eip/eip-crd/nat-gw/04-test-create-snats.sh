#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eipf01.yml
kubectl apply -f 00-eipf02.yml 
kubectl apply -f 00-eip-first-static.yaml
#  show
sleep 5

#  show
kubectl get eip
kubectl get fip


# create nat

kubectl apply -f 02-fip-rule01.yaml
kubectl apply -f 02-fip-eip-static.yaml


sleep 5
kubectl get fip



# fip change eip

kubectl apply -f 02-fip-rule01-change-eip.yaml

sleep 5
kubectl get fip



# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5

kubectl get fip

#  show
kubectl get eip
kubectl get fip
