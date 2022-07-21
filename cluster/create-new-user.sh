#!/bin/bash

CLUSTERNAME=hci
NAMESPACE=yealink
USERNAME=fip-operator
GROUPNAME=newtork

openssl genrsa -out ${USERNAME}.key 2048

CSR_FILE=$USERNAME.csr
KEY_FILE=$USERNAME.key

openssl req -new -key $KEY_FILE -out $CSR_FILE -subj "/CN=$USERNAME/O=$GROUPNAME"

CERTIFICATE_NAME=$USERNAME.$NAMESPACE

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $CERTIFICATE_NAME 
spec:
  signerName: kubernetes.io/kube-apiserver-client
  groups:
  - system:authenticated
  request: $(cat $CSR_FILE | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve $CERTIFICATE_NAME

CRT_FILE=$USERNAME.crt

kubectl get csr $CERTIFICATE_NAME -o jsonpath='{.status.certificate}'  | base64 -d > $CRT_FILE

cat <<EOF | kubectl create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: $NAMESPACE
  name: $CERTIFICATE_NAME
rules:
- apiGroups: ["", "kubeovn.io"]
  resources: ["iptables-eips", "iptables-fip-rules", "iptables-eips/status", "iptables-fip-rules/status"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] # You can also use ["*"]
EOF


cat <<EOF | kubectl create -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $CERTIFICATE_NAME
  namespace: $NAMESPACE
subjects:
- kind: User
  name: $USERNAME
  apiGroup: ""
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: ""
EOF

kubectl config set-credentials $USERNAME \
  --client-certificate=$(pwd)/$CRT_FILE \
  --client-key=$(pwd)/$KEY_FILE

kubectl config set-context $USERNAME-context --cluster=$CLUSTERNAME --namespace=$NAMESPACE --user=$USERNAME

