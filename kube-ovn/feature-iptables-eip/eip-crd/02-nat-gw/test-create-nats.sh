#!/usr/bin/env bash
set -euo pipefail

# create vip

kubectl apply -f vipd01.yaml
kubectl apply -f vipd02.yaml
kubectl apply -f vips01.yaml
kubectl apply -f vipf01.yaml
kubectl apply -f vipf02.yaml
kubectl apply -f vip-no-subnet-01.yaml

sleep 2

# create eip

kubectl apply -f 00-eips01.yml 
kubectl apply -f 00-eipf01.yml
kubectl apply -f 00-eipf02.yml
kubectl apply -f 00-eipd01.yml 
kubectl apply -f 00-eipd02.yml
kubectl apply -f 00-eip-no-subnet-01.yaml

sleep 2

# create nat

kubectl apply -f 01-snat.yml 
kubectl apply -f 02-fip-rule01.yaml
kubectl apply -f 02-fip-rule02.yaml
kubectl apply -f 02-fip-no-subnet-01.yaml
kubectl apply -f 03-dnat01.yaml
kubectl apply -f 03-dnat02.yaml


#  show

kubectl get vip
kubectl get eip
kubectl get snat
kubectl get fip
kubectl get dnat
