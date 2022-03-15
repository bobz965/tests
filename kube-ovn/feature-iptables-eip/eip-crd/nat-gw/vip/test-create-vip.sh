#!/usr/bin/env bash
set -euo pipefail

# create vip

kubectl apply -f vipd01.yaml
kubectl apply -f vipd02-no-ns.yaml
kubectl apply -f vips01.yaml
