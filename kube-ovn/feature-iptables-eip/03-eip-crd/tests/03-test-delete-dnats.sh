#!/usr/bin/env bash

# clean nat

kubectl get eip --show-labels
kubectl get dnat --show-labels


kubectl delete -f 03-dnat01.yaml
sleep 2
kubectl delete -f 03-dnat02.yaml
sleep 2
kubectl delete -f 03-static-dnat01.yaml
sleep 2
kubectl delete -f 03-static-dnat02.yaml
sleep 2

sleep 10 

kubectl get eip --show-labels
kubectl get dnat --show-labels


# clean eip
kubectl delete -f 00-eipd01.yml
sleep 2
kubectl delete -f 00-eipd02.yml
sleep 2
kubectl delete -f 00-eip-first-static.yaml
sleep 2

kubectl get eip --show-labels | grep 'No resources found'

kubectl get dnat --show-labels | grep 'No resources found'

