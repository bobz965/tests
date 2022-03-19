#!/usr/bin/env bash

kubectl get subnet ovn-vpc-external-network

kubectl get eip

# change eip 
kubectl delete -f 00-eipd01.yml 
kubectl delete -f 00-eip-first-dynamic-01-then-static.yaml
kubectl delete -f 00-eip-first-static-then-changed.yaml
kubectl delete -f 00-eip-first-static-02-then-dynamic.yaml
sleep 2


#  show
echo "make sure no eip"
kubectl get eip | grep 'No resources found'

kubectl get subnet ovn-vpc-external-network


