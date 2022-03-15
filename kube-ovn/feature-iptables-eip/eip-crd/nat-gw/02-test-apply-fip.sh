#!/usr/bin/env bash
set -euo pipefail

# create eip

kubectl apply -f 00-eips01.yml 
kubectl apply -f 00-eipf01.yml
kubectl apply -f 00-eipf02.yml
kubectl apply -f 00-eipd01.yml 
kubectl apply -f 00-eipd02.yml
kubectl apply -f 00-eip-static.yaml

sleep 2

# create nat

kubectl apply -f 01-snat.yml 
kubectl apply -f 02-fip-rule01.yaml
kubectl apply -f 02-fip-rule02.yaml
kubectl apply -f 02-fip-eip-static.yaml
kubectl apply -f 03-dnat01.yaml
kubectl apply -f 03-dnat02.yaml


#  show
kubectl get eip
kubectl get snat
kubectl get fip
kubectl get dnat
