#!/usr/bin/env bash

echo "show eip"
echo
kubectl get eip --show-labels
echo "show fip"
echo
kubectl get fip --show-labels

# clean nat
kubectl delete -f 02-fip-rule01.yaml
kubectl delete -f 02-fip-rule02.yaml
sleep 2
kubectl delete -f 02-fip-eip-static.yaml
sleep 2
kubectl delete -f 02-fip-eip-static.yaml
sleep 2


echo "show fip"
echo
kubectl get fip --show-labels|grep 'No resources found'
echo "show eip"
echo
kubectl get eip --show-labels



# clean eip
kubectl delete -f 00-eipf01.yml
sleep 2
kubectl delete -f 00-eipf02.yml
sleep 2
kubectl delete -f 00-eip-first-static-then-changed.yaml
sleep 2



echo "show fip"
echo
kubectl get fip --show-labels |grep 'No resources found'
echo "show eip"
echo
kubectl get eip --show-labels |grep 'No resources found'


