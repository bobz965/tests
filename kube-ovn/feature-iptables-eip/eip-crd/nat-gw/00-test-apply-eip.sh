#!/usr/bin/env bash
set -euo pipefail


echo "show vpc sunbet status before"
kubectl get subnet ovn-vpc-external-network


# create eip
kubectl apply -f 00-eipd01.yml 
sleep 2
kubectl apply -f 00-eip-first-dynamic.yaml
sleep 2
kubectl apply -f 00-eip-first-static.yaml
sleep 2
kubectl apply -f 00-eip-first-static-02.yaml
sleep 5
echo "show eip"

kubectl get eip --show-labels

echo "check eip"

kubectl get eip eipd01 --show-labels

sleep 5

echo "check static eip"
kubectl get eip eip-first-static --show-labels | grep 172.20.10.111
kubectl get eip eip-first-static-02 --show-labels | grep 172.20.10.122


echo "check dynamic eip"
kubectl get eip eip-first-dynamic-01 --show-labels

echo "change eip-first-dynamic-01 ip to 172.20.10.200"

kubectl apply -f  00-eip-first-dynamic-01-then-static.yaml
sleep 5
kubectl get eip eip-first-dynamic-01 --show-labels | grep 172.20.10.200



echo "change eip-first-static ip from 172.20.10.111 to 172.20.10.222"
kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 5
kubectl get eip eip-first-static --show-labels | grep 172.20.10.222



echo "change eip-first-static-02 ip from 172.20.10.111 to dynamic"
kubectl apply -f 00-eip-first-static-02-then-dynamic.yaml
sleep 5
kubectl get eip eip-first-static-02 --show-labels | grep 172.20.10.122


echo "show vpc sunbet status after"
kubectl get subnet ovn-vpc-external-network

echo "show eip"

kubectl get eip --show-labels

kubectl get subnet ovn-vpc-external-network


echo 
echo 
echo 
echo 
echo 
echo 

echo "all succeed !"
