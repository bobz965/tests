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
  namespace: bb1
spec:
  running: true
  template:
    metadata:
      annotations:
        ovn.kubernetes.io/logical_switch: bb1-subnet1
        ovn.kubernetes.io/ip_address: ${ip}
        k8s.v1.cni.cncf.io/networks: bb1/net1
        net1.bb1.ovn.kubernetes.io/logical_switch: bb1-subnet1
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
        resources:
          requests:
            # 注：如果cpu与内存过低，可能会无法在二级k8s中部署multus-cni，具体最低要求尚未确定
            cpu: ${cpu}
            memory: ${memory}Gi
      networks:
      - name: eth0
        pod: {}
      - multus:
          networkName: net1
        name: eth1
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
          url: http://10.120.12.22:8001/centos8-stream-docker.qcow2

EOF

}

for i in {1..3}; do
    create_vm "bb-master-$i" "192.168.0.2$i" 4 8 40
done
for i in {1..3}; do
    create_vm "bb-worker-$i" "192.168.0.6$i" 4 8 40
done
