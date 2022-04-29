#!/usr/bin/env bash

# delete vip

kubectl delete -f vipd01.yaml
kubectl delete -f vips01.yaml
kubectl delete -f vipd02-no-ns.yaml


kubectl delete -f vip-ovn-default-01.yaml
kubectl delete -f vips-ovn-default-01.yaml
kubectl delete -f vip-ovn-vpc-external-network-01.yaml
kubectl delete -f vips-ovn-vpc-external-network-01.yaml
