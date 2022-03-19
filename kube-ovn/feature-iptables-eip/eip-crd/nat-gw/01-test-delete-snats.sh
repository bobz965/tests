#!/usr/bin/env bash
# delete nat

kubectl delete -f 01-snat01.yaml
kubectl delete -f 01-snat02.yaml
kubectl delete -f 01-static-snat01.yaml
kubectl delete -f 01-static-snat02.yaml

# delete eip
kubectl delete -f 00-eip-first-static-then-changed.yaml
kubectl delete -f 00-eips01.yml
kubectl delete -f 00-eips02.yml

#  show
sleep 5

#  show
echo "after delete eip, check if eip label and nat is cleaned"
kubectl get eip --show-labels | grep -v snat 

sleep 10
kubectl get snat

