#!/bin/bash

function delete_vm(){
    name="$1"
    kubectl -n bb1 delete vm $name
}

for i in {1..6}; do
    delete_vm "bb-master-$i"
    delete_vm "bb-worker-$i"
done

