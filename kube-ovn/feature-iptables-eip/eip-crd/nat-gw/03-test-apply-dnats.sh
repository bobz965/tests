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
kubectl apply -f 03-static-dnat01.yaml
kubectl apply -f 03-static-dnat02.yaml


sleep 5

echo "check dnat "

kubectl get dnat dnat01 --show-labels  | grep "192.168.0.5" | grep eipd01 | grep 8888 | grep 80 | grep tcp
kubectl get dnat dnat02 --show-labels  | grep "192.168.0.6" | grep eipd02 | grep 8888 | grep 80 | grep tcp 
kubectl get dnat static-dnat01 --show-labels | grep "192.168.0.15" | grep eip-first-static | grep 172.20.10.111 | grep 8888 | grep 80 | grep tcp
kubectl get dnat static-dnat02 --show-labels | grep "192.168.0.16" | grep eip-first-static | grep 172.20.10.111 | grep 8888 | grep 80 | grep tcp

kubectl get dnat --show-labels

echo "dnat02 change eip"
kubectl apply -f 03-dnat01-change-eip.yaml
sleep 5
kubectl get dnat dnat01 --show-labels  | grep "192.168.0.5" | grep eipd02 | grep 8888 | grep 80 | grep tcp


sleep 5
kubectl get dnat --show-labels

# only eip ip changed 
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5


# echo "check snat after eip changed"
sleep 5
echo "just change eip, check if snat changed"
kubectl get dnat static-dnat01 --show-labels | grep "192.168.0.15" | grep eip-first-static | grep 172.20.10.222 | grep 8888 | grep 80 | grep tcp
kubectl get dnat static-dnat02 --show-labels | grep "192.168.0.16" | grep eip-first-static | grep 172.20.10.222 | grep 8888 | grep 80 | grep tcp


#  show
kubectl get eip --show-labels
kubectl get dnat --show-labels


echo 
echo 
echo 
echo 
echo 
echo 

echo "all succeed !"


