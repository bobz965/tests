#!/bin/bash
set -xeuo pipefail

NAMESPACE=${NAMESPACE:-default}

# 为curl设置HTTP代理服务器，且开启自动重定向的功能
CURL='curl -s -L -x http://netproxy.yealinkops.com:8123'

# 从github中检索最新stable版本号
REPO="kubevirt/csi-driver"
VERSION="master"

URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/deploy"

CONFIG=`cat infracluster-kubeconfig.yaml | base64 -w0`

# 创建【kubevirt-csi-driver】命名空间
${CURL} "${URL}/000-namespace.yaml" | kubectl apply -f - 

# 导入访问一级k8s的kubeconfig
cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: infra-cluster-credentials
  namespace: kubevirt-csi-driver
data:
  kubeconfig: ${CONFIG}
EOF

# 创建【driver-config】配置项
cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: driver-config
  namespace: kubevirt-csi-driver
data:
  infraClusterNamespace: ${NAMESPACE}
  infraClusterLabels: tenant=${NAMESPACE}
EOF

# 创建 CSIDriver
${CURL} "${URL}/000-csi-driver.yaml" |kubectl apply -f -

# 创建 帐号、角色与权限
${CURL} "${URL}/020-autorization.yaml" |kubectl apply -f -

# 创建【kubevirt-csi-node】DaemonSet
${CURL} "${URL}/030-node.yaml" | sed -e 's|\<quay\.io\>|yealink.top|g' | kubectl apply -f -

# 创建【kubevirt-csi-controller】Deployment
${CURL} "${URL}/040-controller.yaml" | sed -e 's|\<quay\.io\>|yealink.top|g' | kubectl apply -f -

# 等待部署完成
kubectl -n kubevirt-csi-driver rollout status daemonset  kubevirt-csi-node
kubectl -n kubevirt-csi-driver rollout status deployment kubevirt-csi-controller

