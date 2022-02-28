#!/usr/bin/env bash

# clean nat

kubectl delete -f 01-snat.yml 
kubectl delete -f 02-fip-rule01.yaml
kubectl delete -f 02-fip-rule02.yaml
kubectl delete -f 03-dnat01.yaml
kubectl delete -f 03-dnat02.yaml


# clean eip

kubectl delete -f 00-eips01.yml 
kubectl delete -f 00-eipf01.yml
kubectl delete -f 00-eipf02.yml
kubectl delete -f 00-eipd01.yml 
kubectl delete -f 00-eipd02.yml

sleep 2

# clean vip

kubectl delete -f vipd01.yaml
kubectl delete -f vipd02.yaml
kubectl delete -f vips01.yaml
kubectl delete -f vipf01.yaml
kubectl delete -f vipf02.yaml

sleep 2

