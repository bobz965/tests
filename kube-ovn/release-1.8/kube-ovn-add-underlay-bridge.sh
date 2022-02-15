#!/usr/bin/env bash

# 目前还不支持桥接多个网卡，这个功能我们正在做
# 可以手动创建再桥接，并添加bridge-mapping。之后就可以创建vlan和subnet使用了
# ovs-vsctl get open . external-ids:ovn-bridge-mappings  获取当前设置
# ovs-vsctl set open . external-ids:ovn-bridge-mappings=<CURRENT_MAPPINGS>,provider2:$br

br="br-storage"
storage_nic="eth3"

master_prefix="okd-m"
for i in {1..3}; do
    kubectl-ko vsctl $master_prefix$i add-br $br   
    kubectl-ko vsctl $master_prefix$i add-port $br $storage_nic
    kubectl-ko vsctl $master_prefix$i get open . external-ids:ovn-bridge-mappings
    kubectl-ko vsctl $master_prefix$i set open . external-ids:ovn-bridge-mappings=provider:br-provider,provider2:$br
done

worker_prefix="okd-w"

for i in {1..2}; do
    kubectl-ko vsctl $worker_prefix$i add-br $br   
    kubectl-ko vsctl $worker_prefix$i add-port $br $storage_nic
    kubectl-ko vsctl $worker_prefix$i get open . external-ids:ovn-bridge-mappings
    kubectl-ko vsctl $worker_prefix$i set open . external-ids:ovn-bridge-mappings=provider:br-provider,provider2:$br
done



