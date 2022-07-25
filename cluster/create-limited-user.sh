#!/bin/bash

CLUSTER_NAME="hci"
NAMESPACE=yealink
USERNAME=fip-operator
GROUPNAME=newtork

# 1. create ns if not exist
# kubectl create namespace $NAMESPACE

# 2. create service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
EOF

# 3. create role
## show  your cluster k8s api
## # kubectl api-versions| grep  rbac      
## # rbac.authorization.k8s.io/v1

cat <<EOF | kubectl apply -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
rules:
- apiGroups: ["", "kubeovn.io"]
  resources: ["iptables-eips", "iptables-fip-rules", "iptables-eips/status", "iptables-fip-rules/status"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] # You can also use ["*"]
EOF

# 4. bind role to user

cat <<EOF | kubectl apply -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $USERNAME
  namespace: $NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $USERNAME
EOF

# 5. get service account token go access k8s on dashboard or through cmd

export NAMESPACE="$NAMESPACE"
export K8S_USER="$USERNAME"
account_token=`kubectl -n ${NAMESPACE} describe secret $(kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'\n`
echo "token: $account_token"

secretname=`kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}'`
certificate=`kubectl  -n ${NAMESPACE} get secret $secretname -o "jsonpath={.data['ca\.crt']}"`

# 6. create kube config

cat <<EOF > /tmp/fip-kube-config
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
USERNAME=fip-operator
kubectl get ServiceAccount  -A | grep "$USERNAME"
kubectl get Role -A | grep "$USERNAME"
kubectl get RoleBinding -A | grep "$USERNAME"


# ref: https://docs.bitnami.com/tutorials/configure-rbac-in-your-kubernetes-cluster/#use-case-1-create-user-with-limited-namespace-access
# key ref: https://computingforgeeks.com/restrict-kubernetes-service-account-users-to-a-namespace-with-rbac/
