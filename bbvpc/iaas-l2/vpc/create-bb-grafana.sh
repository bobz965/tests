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
    spec:
      domain:
        devices:
          disks:
          - name: pvcdisk
          - name: cloudinitdisk
          interfaces:
          - name: eth0
            bridge: {}
        resources:
          requests:
            # 注：如果cpu与内存过低，可能会无法在二级k8s中部署multus-cni，具体最低要求尚未确定
            cpu: ${cpu}
            memory: ${memory}Gi
      networks:
      - name: eth0
        pod: {}
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
          url: http://mirrors.yealink.top/Cloud-Image/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2c

EOF

}

create_vm bbvpc-grafana 192.168.0.70 8 16 100
