#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-"bb1"}
SSH_KEY_FILE="${HOME}/.ssh/id_rsa.pub"
kubectl -n ${NAMESPACE} create secret generic ssh-pub-key --from-file=default="${SSH_KEY_FILE}"

