#!/usr/bin/env bash

# clean nat
kubectl delete -f 03-dnat01.yaml
sleep 2
kubectl delete -f 03-dnat02.yaml
sleep 2


# clean eip
kubectl delete -f 00-eipd01.yml
sleep 2
kubectl delete -f 00-eipd02.yml
sleep 2
kubectl delete -f 00-eip-first-static.yaml
sleep 2



