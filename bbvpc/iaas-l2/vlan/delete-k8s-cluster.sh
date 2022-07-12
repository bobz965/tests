#!/bin/bash
set -euo pipefail

function delete_vm(){
    name="$1"
    kubectl -n l2k8s-vlan delete vm $name
}

for i in {1..3}; do
    delete_vm "k8s-master-$i"
    delete_vm "k8s-worker-$i"
done

