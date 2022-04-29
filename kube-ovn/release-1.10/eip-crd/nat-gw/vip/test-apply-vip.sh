#!/usr/bin/env bash
set -euo pipefail

# create vip
echo "show vpc sunbet status before"
kubectl get subnet vpc1-subnet1 
kubectl get subnet ovn-default  
kubectl get subnet ovn-vpc-external-network

kubectl apply -f vipd01.yaml
sleep 2 
kubectl apply -f vipd02-no-ns.yaml
sleep 2 
kubectl apply -f vips01.yaml
sleep 2 

kubectl apply -f vip-ovn-default-01.yaml 
sleep 2 
kubectl apply -f vips-ovn-default-01.yaml
sleep 2 
kubectl apply -f vip-ovn-vpc-external-network-01.yaml
sleep 2 

kubectl apply -f vips-ovn-vpc-external-network-01.yaml
sleep 2 

kubectl get vip vipd01 
kubectl get vip vipd02
kubectl get vip vips01 | grep 192.168.0.100


kubectl get vip vip-ovn-default-01
kubectl get vip vips-ovn-default-01 | grep 10.16.0.100

kubectl get vip vip-ovn-vpc-external-network-01 
kubectl get vip vips-ovn-vpc-external-network-01 | grep 172.20.10.100


echo "show vpc sunbet status before"
kubectl get subnet vpc1-subnet1 
kubectl get subnet ovn-default  
kubectl get subnet ovn-vpc-external-network
