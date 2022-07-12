#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-default}

# 为curl设置HTTP代理服务器，且开启自动重定向的功能
CURL='curl -s -L -x http://netproxy.yealinkops.com:8123'

# 从github中检索最新stable版本号
REPO="kubevirt/csi-driver"
VERSION="master"

URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/deploy"

# 在${NAMESPACE}命名空间下创建名为【kubevirt-csi】的账号
${CURL} "${URL}/infra-cluster-service-account.yaml" |kubectl -n ${NAMESPACE} apply -f -

# 获得【kubevirt-csi】帐号的secret名称
SECRET_NAME=`kubectl -n ${NAMESPACE} get ServiceAccount kubevirt-csi -o jsonpath={.secrets[0].name}`
# 获得【kubevirt-csi】帐号的token
SECRET_TOKEN=`kubectl -n ${NAMESPACE} get secrets ${SECRET_NAME} -o jsonpath={.data.token}|base64 -d`

# 获得api-server的CA证书
CA=`kubectl -n kube-system get configmaps kube-root-ca.crt -o jsonpath={.data.ca'\.'crt}|base64 -w0`

# 获得api-server的地址
APISERVER=`kubectl -n kube-system get configmaps kubeadm-config -o jsonpath={.data.ClusterConfiguration}|grep '^controlPlaneEndpoint'|awk '{print $2}'`

# 生成新的kubeconfig文件
cat > infracluster-kubeconfig.yaml <<-EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CA}
    server: https://${APISERVER}
  name: infra-cluster
contexts:
- context:
    cluster: infra-cluster
    namespace: ${NAMESPACE}
    user: kubevirt-csi
  name: only-context
current-context: only-context
kind: Config
preferences: {}
users:
- name: kubevirt-csi
  user:
    token: ${SECRET_TOKEN}
EOF

# 测试
kubectl --kubeconfig infracluster-kubeconfig.yaml  -n ${NAMESPACE} get virtualmachineinstances
