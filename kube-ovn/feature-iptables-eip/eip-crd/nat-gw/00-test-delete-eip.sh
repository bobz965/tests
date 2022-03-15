#!/usr/bin/env bash


kubectl get eip

# change eip 
kubectl delete -f 00-eipd01.yml 
kubectl delete -f 00-eip-first-dynamic-01-then-static.yaml
kubectl delete -f 00-eip-first-static-then-changed.yaml
sleep 2


#  show
kubectl get eip
