#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-"bbvpc01"}
SSH_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
USER_DATA=$(cat <<-EOF | base64 -w 0
#cloud-config
ssh_authorized_keys:
  - ${SSH_KEY}
system_info:
  default_user:
    name: yealink
    plain_text_passwd: yealink.top
    lock_passwd: false
final_message: "login as 'yealink' user. default password: 'yealink.top'. use 'sudo' for root."
bootcmd:
- echo "this is bootcmd"
runcmd:
- echo "this is runcmd"
EOF
)

cat <<-EOF | kubectl apply -f -
kind: Secret
apiVersion: v1
data:
  userdata: ${USER_DATA}
metadata:
  name: cloudinit-userdata
  namespace: ${NAMESPACE}
EOF
