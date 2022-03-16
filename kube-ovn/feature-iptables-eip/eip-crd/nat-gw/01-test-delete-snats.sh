#!/usr/bin/env bash
# delete nat

kubectl delete -f 01-snat01.yaml
kubectl delete -f 01-snat02.yaml

# delete eip
kubectl delete -f 00-eip-first-static-then-changed.yaml
kubectl delete -f 00-eips01.yml
kubectl delete -f 00-eips02.yml

#  show
sleep 5

#  show
kubectl get eip
kubectl get snat

