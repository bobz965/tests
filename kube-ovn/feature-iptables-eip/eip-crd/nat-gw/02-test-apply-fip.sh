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


# create nat
kubectl apply -f 02-fip-rule01.yaml
kubectl apply -f 02-fip-rule02.yaml
kubectl apply -f 02-fip-eip-static.yaml


sleep 5
kubectl get fip --show-labels


echo "check fip"

kubectl get fip fip01 --show-labels  | grep eipf01 | grep "192.168.0.3"
kubectl get fip fip02 --show-labels  | grep eipf02 | grep "192.168.0.4"
kubectl get fip fip-eip-static --show-labels  | grep "eip-first-static" | grep "192.168.0.7" | grep "172.20.10.111"


# fip change eip --show-labels

echo "fip rule01 change eip"
kubectl apply -f 02-fip-rule01-change-eip.yaml

sleep 5
echo "check fip rule01 if change eip"

kubectl get fip fip01 --show-labels  | grep eipf02 | grep "192.168.0.3"


# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5

echo "check static-fip01 if change eip"
kubectl get fip fip-eip-static --show-labels  | grep "eip-first-static" | grep "192.168.0.7" | grep "172.20.10.222"

#  show
kubectl get eip --show-labels
kubectl get fip --show-labels


echo 
echo 
echo 
echo 
echo 
echo 

echo "all succeed !"



