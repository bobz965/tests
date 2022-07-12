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


# 导入访问一级k8s的kubeconfig
cat <<-EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: infra-cluster-credentials
  namespace: kubevirt-csi-driver
data:
  kubeconfig: ${CONFIG}
EOF

# 创建【driver-config】配置项
cat <<-EOF > configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: driver-config
  namespace: kubevirt-csi-driver
data:
  infraClusterNamespace: ${NAMESPACE}
  infraClusterLabels: tenant=${NAMESPACE}
EOF


