#!/usr/bin/env bash

# clean nat
kubectl delete -f 02-fip-rule01.yaml
sleep 2
kubectl delete -f 02-fip-eip-static.yaml
sleep 2


# clean eip
kubectl delete -f 00-eipf01.yml
sleep 2
kubectl delete -f 00-eipf02.yml
sleep 2
kubectl delete -f 00-eip-first-static-then-changed.yaml
sleep 2



