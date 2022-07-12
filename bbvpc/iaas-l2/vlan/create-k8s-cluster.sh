#!/bin/bash
set -euo pipefail

function create_vm(){
	name="$1"
	ip="$2"
    cpu="$3"
    memory="$4"
    disk="$5"
	cat <<-EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: ${name}
  namespace: l2k8s-vlan
spec:
  running: true
  template:
    metadata:
      annotations:
        # 注意：这些注解不是写上第一级的'metadata'下，而是在'template/metadata'下。
        # 需要固定IP地址，否则二级k8s在重启后可能会故障
        ovn.kubernetes.io/ip_address: ${ip}
        # 第二、三网卡用作二级k8s的桥接网卡，可以无需指定IP。
        # 目前无法实现只创建接口但不分配IP的功能，所以每个接口还是会占用一个IP.
        net1.l2k8s-vlan.ovn.kubernetes.io/logical_switch: underlay
        net2.l2k8s-vlan.ovn.kubernetes.io/logical_switch: vlan-48
    spec:
      domain:
        devices:
          disks:
          - name: pvcdisk
          - name: cloudinitdisk
          interfaces:
          - name: eth0
            bridge: {}
          - name: eth1
            bridge: {}
          - name: eth2
            bridge: {}
        resources:
          requests:
            # 注：如果cpu与内存过低，可能会无法在二级k8s中部署multus-cni，具体最低要求尚未确定
            cpu: ${cpu}
            memory: ${memory}Gi
      networks:
      - name: eth0
        pod: {}
      - name: eth1
        multus:
          networkName: net1
      - name: eth2
        multus:
          networkName: net2
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
        - 10.5.200.10
        - 10.100.1.10
        options:
        - name: ndots
          value: "2"
      volumes:
      - name: pvcdisk
        dataVolume:
          name: ${name}
      - name: cloudinitdisk
        cloudInitConfigDrive:
          userData: "#cloud-config"
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: ssh-pub-key
          propagationMethod:
            configDrive: {}
  dataVolumeTemplates:
  - metadata:
      name: ${name}
    spec:
      pvc:
        volumeMode: Block
        accessModes:
        - ReadWriteMany
        resources:
          requests:
            storage: ${disk}Gi
      source:
        http:
          # 由于vlan模式下的cdi-importer的dns有问题，所以下面的url只能使用ip地址，不能用域名
          url: http://10.5.32.1/Cloud-Image/CentOS-7-x86_64-Docker-CE.qcow2

EOF

}

for i in {1..3}; do
    create_vm "k8s-master-$i" "10.5.203.1$i" 2 4 20
    create_vm "k8s-worker-$i" "10.5.203.2$i" 4 8 40
done

