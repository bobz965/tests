#!/usr/bin/env bash
set -euo pipefail

# create vip
echo "show vpc sunbet status before"
kubectl get subnet vpc1-subnet1 

kubectl apply -f vipd01.yaml
sleep 2 
kubectl apply -f vipd02-no-ns.yaml
sleep 2 
kubectl apply -f vips01.yaml
sleep 2 


kubectl get vip vipd01 
kubectl get vip vipd02
kubectl get vip vips01 | grep 192.168.0.100



echo "show vpc sunbet status before"
kubectl get subnet vpc1-subnet1 

