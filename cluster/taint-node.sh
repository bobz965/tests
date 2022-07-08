# 除非指定容忍该污点 否则无法调度
# taint common node
#kubectl taint node hci-compute-1 dedicated=common:NoSchedule
#kubectl taint node hci-compute-2 dedicated=common:NoSchedule
#kubectl taint node hci-compute-3 dedicated=common:NoSchedule
#kubectl taint node hci-compute-4 dedicated=common:NoSchedule
#kubectl taint node hci-compute-5 dedicated=common:NoSchedule
#kubectl taint node hci-compute-6 dedicated=common:NoSchedule
#kubectl taint node hci-compute-7 dedicated=common:NoSchedule
#kubectl taint node hci-compute-8 dedicated=common:NoSchedule
#kubectl taint node hci-compute-9 dedicated=common:NoSchedule
#kubectl taint node hci-compute-10 dedicated=common:NoSchedule
#kubectl taint node hci-compute-11 dedicated=common:NoSchedule
#kubectl taint node hci-compute-12 dedicated=common:NoSchedule

# 作为common节点, 应该是要绝大部分对网络对磁盘没要求的业务负载都可以直接调度到，所以不配置污点使用起来最为方便

# label and taint xnet node
# 作为专用网络节点, 基于label划分node组，pod 根据label选择到node组，且配置容忍才可调度到node组
kubectl label node hci-compute-xnet-1 node.kubevirt.io/dedicated=xnet
kubectl label node hci-compute-xnet-2 node.kubevirt.io/dedicated=xnet
kubectl label node hci-compute-xnet-3 node.kubevirt.io/dedicated=xnet
kubectl label node hci-compute-xnet-4 node.kubevirt.io/dedicated=xnet
kubectl label node hci-compute-xnet-5 node.kubevirt.io/dedicated=xnet
kubectl label node hci-compute-xnet-6 node.kubevirt.io/dedicated=xnet
kubectl taint node hci-compute-xnet-1 node.kubevirt.io/dedicated=xnet:NoSchedule
kubectl taint node hci-compute-xnet-2 node.kubevirt.io/dedicated=xnet:NoSchedule
kubectl taint node hci-compute-xnet-3 node.kubevirt.io/dedicated=xnet:NoSchedule
kubectl taint node hci-compute-xnet-4 node.kubevirt.io/dedicated=xnet:NoSchedule
kubectl taint node hci-compute-xnet-5 node.kubevirt.io/dedicated=xnet:NoSchedule
kubectl taint node hci-compute-xnet-6 node.kubevirt.io/dedicated=xnet:NoSchedule

# label and taint xsto node 
kubectl label node hci-compute-xsto-1 node.kubevirt.io/dedicated=xsto
kubectl label node hci-compute-xsto-2 node.kubevirt.io/dedicated=xsto
kubectl label node hci-compute-xsto-3 node.kubevirt.io/dedicated=xsto
kubectl taint node hci-compute-xsto-1 node.kubevirt.io/dedicated=xsto:NoSchedule
kubectl taint node hci-compute-xsto-2 node.kubevirt.io/dedicated=xsto:NoSchedule
kubectl taint node hci-compute-xsto-3 node.kubevirt.io/dedicated=xsto:NoSchedule

# label and taint ctrl
kubectl label node hci-ctrl-1 node.kubevirt.io/dedicated=ctrl
kubectl label node hci-ctrl-2 node.kubevirt.io/dedicated=ctrl
kubectl label node hci-ctrl-3 node.kubevirt.io/dedicated=ctrl
kubectl taint node hci-ctrl-1 node.kubevirt.io/dedicated=ctrl:NoSchedule
kubectl taint node hci-ctrl-2 node.kubevirt.io/dedicated=ctrl:NoSchedule
kubectl taint node hci-ctrl-3 node.kubevirt.io/dedicated=ctrl:NoSchedule

