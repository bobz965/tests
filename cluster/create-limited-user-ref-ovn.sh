#!/bin/bash

CLUSTER_NAME="hci"
NAMESPACE=yealink
USERNAME=fip-user
#GROUPNAME=newtork

# 1. get service account token go access k8s on dashboard or through cmd

export NAMESPACE="$NAMESPACE"
export K8S_USER="$USERNAME"
account_token=`kubectl -n ${NAMESPACE} describe secret $(kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'\n`
echo "token: $account_token"

secretname=`kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}'`
certificate=`kubectl  -n ${NAMESPACE} get secret $secretname -o "jsonpath={.data['ca\.crt']}"`

# 6. create kube config

cat <<EOF > /tmp/fip-user-kube-config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $certificate
    server: https://hci-ctrl.iaas.yealinkops.com:6443
  name: $CLUSTER_NAME

contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: ${NAMESPACE}
    user: ${K8S_USER}
  name: ${K8S_USER}

current-context: ${K8S_USER}
kind: Config
preferences: {}

users:
- name: ${K8S_USER}
  user:
    token: $account_token
    client-key-data: $certificate
EOF

exit 0
USERNAME=fip-user
kubectl get ServiceAccount  -A | grep "$USERNAME"
kubectl get Role -A | grep "$USERNAME"
kubectl get RoleBinding -A | grep "$USERNAME"

# ref: https://docs.bitnami.com/tutorials/configure-rbac-in-your-kubernetes-cluster/#use-case-1-create-user-with-limited-namespace-access
# key ref: https://computingforgeeks.com/restrict-kubernetes-service-account-users-to-a-namespace-with-rbac/
