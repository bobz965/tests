#!/usr/bin/env bash

# delete vip

kubectl delete -f vipd01.yaml
kubectl delete -f vips01.yaml
kubectl delete -f vipd02-no-ns.yaml
