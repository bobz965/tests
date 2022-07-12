#!/usr/bin/env bash
set -euo pipefail

# create vip

kubectl apply -f vip-bb-master-f01.yaml
kubectl apply -f vip-bb-master-f02.yaml
kubectl apply -f vip-bb-master-f03.yaml

sleep 2

# create eip

kubectl apply -f 00-eip-bb-master-01.yaml
kubectl apply -f 00-eip-bb-master-02.yaml
kubectl apply -f 00-eip-bb-master-03.yaml
kubectl apply -f 00-eips01.yml

sleep 2

# create nat

kubectl apply -f 02-fip-bb-master-01.yaml
kubectl apply -f 02-fip-bb-master-02.yaml
kubectl apply -f 02-fip-bb-master-03.yaml
kubectl apply -f 01-snat.yml


#  show

kubectl get vip
kubectl get eip
kubectl get snat
kubectl get fip
kubectl get dnat
