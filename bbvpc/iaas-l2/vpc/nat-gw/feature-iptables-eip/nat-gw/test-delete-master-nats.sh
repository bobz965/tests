#!/usr/bin/env bash
set -euo pipefail


# delete nat

kubectl delete -f 02-fip-bb-master-01.yaml
kubectl delete -f 02-fip-bb-master-02.yaml
kubectl delete -f 02-fip-bb-master-03.yaml

sleep 2

# delete eip

kubectl delete -f 00-eip-bb-master-01.yaml
kubectl delete -f 00-eip-bb-master-02.yaml
kubectl delete -f 00-eip-bb-master-03.yaml

sleep 2



# delete vip

kubectl delete -f vip-bb-master-f01.yaml
kubectl delete -f vip-bb-master-f02.yaml
kubectl delete -f vip-bb-master-f03.yaml



#  show

kubectl get vip
kubectl get eip
kubectl get snat
kubectl get fip
kubectl get dnat
