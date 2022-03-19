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
sleep 5
echo "show eip"
kubectl get eip --show-labels

# create nat

sleep 2

echo "show snat"

kubectl apply -f 01-snat01.yaml
sleep 2
kubectl apply -f 01-snat02.yaml
sleep 2
kubectl apply -f 01-static-snat01.yaml
sleep 2
kubectl apply -f 01-static-snat02.yaml
sleep 2



# echo "check snat"

kubectl get snat snat01 --show-labels  | grep "192.168.0.0/24" | grep eips01
kubectl get snat snat02 --show-labels  | grep "192.168.10.0/24" |grep eips02
kubectl get snat static-snat01 --show-labels | grep "192.168.20.0/24" | grep eip-first-static | grep 172.20.10.111
kubectl get snat static-snat02 --show-labels | grep "192.168.30.0/24" | grep eip-first-static | grep 172.20.10.111


echo "show snat"
kubectl get snat --show-labels

# fip change eip

echo "snat01 change eip"
kubectl apply -f 01-snat01-change-eip.yaml
sleep 5
kubectl get snat snat01 --show-labels  | grep eips02 | grep "192.168.0.0/24" 

# only eip ip changed 
echo "just change eip, then snat changed"
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5

# echo "check snat after eip changed"
echo "just change eip, check if snat changed"
kubectl get snat static-snat01 --show-labels | grep "192.168.20.0/24" | grep eip-first-static | grep 172.20.10.222
kubectl get snat static-snat02 --show-labels | grep "192.168.30.0/24" | grep eip-first-static | grep 172.20.10.222

#  show
kubectl get eip --show-labels | grep snat 

kubectl get snat --show-labels | grep eip



echo 
echo 
echo 
echo 
echo 
echo 

echo "all succeed !"







