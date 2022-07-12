#!/bin/bash

# 创建【kubevirt-csi-controller】Deployment
${CURL} "${URL}/040-controller.yaml" | sed -e 's|\<quay\.io\>|yealink.top|g' | kubectl delete -f -

# 创建【kubevirt-csi-node】DaemonSet
${CURL} "${URL}/030-node.yaml" | sed -e 's|\<quay\.io\>|yealink.top|g' | kubectl delete -f -

# 创建 帐号、角色与权限
${CURL} "${URL}/020-autorization.yaml" |kubectl delete -f -

# 创建 CSIDriver
${CURL} "${URL}/000-csi-driver.yaml" |kubectl delete -f -

kubectl -n kubevirt-csi-driver delete cm driver-config
kubectl -n kubevirt-csi-driver delete secret infra-cluster-credentials
kubectl delete ns kubevirt-csi-driver
