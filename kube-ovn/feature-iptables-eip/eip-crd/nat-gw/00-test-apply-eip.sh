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

kubectl get eip eipd01 --show-labels


kubectl get eip eip-first-static --show-labels | grep 172.20.10.111


kubectl get eip eip-first-dynamic-01 --show-labels

echo "change eip-first-dynamic-01 ip to 172.20.10.200"

kubectl apply -f  00-eip-first-dynamic-01-then-static.yaml
sleep 2
kubectl get eip eip-first-dynamic-01 --show-labels | grep 172.20.10.200



echo "change eip-first-static ip from 172.20.10.111 to 172.20.10.222"

kubectl apply -f 00-eip-first-static-then-changed.yaml
sleep 2
kubectl get eip eip-first-static --show-labels | grep 172.20.10.222

echo "show vpc sunbet status after"
kubectl get subnet ovn-vpc-external-network
