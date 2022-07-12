#!/bin/bash
# 
#*************************************************************
# 文件：deploy-k8s.sh
# 描述：部署一个高可用 kubernetes 集群
# Usage: $0 [-n <cluster name>] [-c <CNI type>] [-b <LB type>] [-h|-?]
#    -n <cluster name>   Specify the cluster name. default is 'k8s-cluster'.
#    -c <CNI type>       Specify the CNI type. Can be [none|flannel|calico|kubeovn|ipvlan], default is 'none'.
#    -b <LB type>        Specify the LoadBalancer type. Can be [kubevip|metallb], default is 'none'.
#    -w <Worker Nums>    Specify the Worker Node count. default is 3.
#    -h|-?               pring usage
#*************************************************************

# set命令参数说明:
# -e 若指令传回值不等于0，则立即退出shell
# -u 当执行时使用到未定义过的变量，则显示错误信息
# -o 找开特殊选项
# -o pipefail 表示在管道连接的命令序列中，只要有任何一个命令返回非0值，则整个管道返回非0值
set -euo pipefail

# 为curl设置HTTP代理服务器，且开启自动重定向的功能
CURL='curl -s -L'
PXCURL='curl -s -L -x http://netproxy.yealinkops.com:8123'


# 设置主机名
HOSTNAME=${HOSTNAME:-}

# 使用指定版本的 docker
DOCKER_VERSION=${DOCKER_VERSION:-}

# 使用指定版本的 kubernetes
K8S_VERSION=${K8S_VERSION:-"1.23.3"}

# 定义apiserver的端口号
K8S_CP_PORT=${K8S_CP_PORT:-"6443"}

# 定义k8s集群名称
K8S_CLUSTER_NAME=${K8S_CLUSTER_NAME:-"k8s-shanghai"}

# 定义pod子网CIDR
# 可用地址： 65534
# 起始地址： 172.24.0.1
# 结束地址： 172.24.255.254
# 子网掩码： 255.255.0.0
# 网络地址： 172.24.0.0
# 广播地址： 172.24.255.255
K8S_POD_CIDR="172.17.0.0/16"

# 定义service子网CIDR
# 可用地址： 262142
# 起始地址： 172.27.0.1
# 结束地址： 172.31.255.254
# 子网掩码： 255.252.0.0
# 网络地址： 172.27.0.0
# 广播地址： 172.31.255.255
K8S_SVC_CIDR="172.27.0.0/16"

K8S_IPVLAN_CIDR="172.18.0.0/16"
K8S_IPVLAN_GATEWAY="172.18.0.1"
K8S_IPVLAN_RANGE_START="172.18.128.0"
K8S_IPVLAN_RANGE_END="172.18.191.255"

K8S_NODELOCALDNS_IP="169.254.20.10"

# 定义要使用的cni插件名。支持 flannel、calico、kubeovn
K8S_CNI=${K8S_CNI:-"ipvlan"}

# 使用哪种 Load Balancer。支持 kubevip、metallb
K8S_LB=${K8S_LB:-"kubevip"}
# 定义LB的IP地址可用范围
K8S_LB_SVC_EIP_RANGE=${K8S_LB_SVC_EIP_RANGE:-"172.17.64.0-172.17.127.255"}

KUBE_VIP_VERSION="v0.4.2"

# 允许并限定metallb controller只能运行在控制节点上
METALLB_CTRLER_IN_CP=${METALLB_CTRLER_IN_CP:-"false"}

# 定义etcd的数据存储目录
ETCD_DATA_DIR="${ETCD_DATA_DIR:-"/home/etcd"}"

# 定义控制平面地址
declare -l    _k8s_cp_endpoint="${K8S_CLUSTER_NAME}.yealink.top:${K8S_CP_PORT}"

# 只是初始化k8s集群环境，但并不实际部署k8s集群
declare -i    _k8s_init_only=0
# Worker节点的数量
declare -i    _k8s_worker_num=3

function usage(){
   cat <<-EOF
Usage: $0 [-n <cluster name>] [-c <CNI type>] [-b <LB type> [-h|-?]
    -n <cluster name>   Specify the cluster name. default is 'k8s-cluster'.
    -c <CNI type>       Specify the CNI type. Can be [none|flannel|calico|kubeovn|ipvlan], default is 'none'.
    -b <LB type>        Specify the LoadBalancer type. Can be [kubevip|metallb], default is 'none'.
    -w <Worker Nums>    Specify the Worker Node count. default is 3.
    -h|-?               pring usage
options:
    --init-only         Only initialize the k8s environment, but do not deploy the k8s cluster.
EOF
}

while getopts "n: c: b: w: :h? -:" opt; do
    case ${opt} in
        -)  
            echo "OPTIND=$OPTIND"
            echo "OPTARG=$OPTARG"
            case "${OPTARG}" in
                init-only)
                    _k8s_init_only=1
                    ;;
                *)
                    error "Unknown option --${OPTARG}" && exit -1
                    ;;
            esac
            ;;
        n)
            K8S_CLUSTER_NAME=${OPTARG}
            _k8s_cp_endpoint="${K8S_CLUSTER_NAME}.yealink.top:${K8S_CP_PORT}"
            ;;
        c)
            declare -l cni=${OPTARG}
            if [ "${cni}" != "none" -a "${cni}" != "flannel" -a "${cni}" != "calico" -a "${cni}" != "kubeovn" -a "${cni}" != "ipvlan" ]; then
                error "Invalid CNI type: ${COLOR_PURPLE}${OPTARG}" && exit -1
            fi
            K8S_CNI=${cni}
            ;;
        b)
            declare -l lb=${OPTARG}
            if [ "${lb}" != "none" -a "${lb}" != "kubevip" -a "${lb}" != "metallb" ]; then
                error "Invalid LoadBalancer type: ${COLOR_PURPLE}${OPTARG}" && exit -1
            fi
            K8S_LB=${lb}
            ;;
        w)
            _k8s_worker_num=${OPTARG}
            ;;

        h|?)
            usage && exit 0
            ;;
        *)
            usage && error "unknown command"  && exit 1
        ;;
    esac
done

source <(${CURL} http://mirrors.yealink.top/scripts/kubernetes/deploy/common.sh)

get_self
get_default_network
get_cidr_detail ${_default_cidr}

# 获取IP地址的前三位
declare -r    _ip_prefix=`echo ${_default_ip}|awk -F. '{printf "%d.%d.%d",$1,$2,$3}'`
# 定义各节点的IP地址
declare -r -a _k8s_master=(${_ip_prefix}.11 ${_ip_prefix}.12 ${_ip_prefix}.13)
declare -r -a _k8s_worker=($(for i in `seq 1 ${_k8s_worker_num}`; do echo "${_ip_prefix}.$[$i+20] "; done))
declare -r -a _k8s_node=(${_k8s_master[*]} ${_k8s_worker[*]})

# 定义各节点的主机名
declare -r -l _k8s_hostname_prefix=${_k8s_hostname_prefix:-"${K8S_CLUSTER_NAME}-"}
declare -r -a _k8s_master_hostname=(`for i in "${!_k8s_master[@]}"; do echo "${_k8s_hostname_prefix}master-$[$i+1] ";done`)
declare -r -a _k8s_worker_hostname=(`for i in "${!_k8s_worker[@]}"; do echo "${_k8s_hostname_prefix}worker-$[$i+1] ";done`)
declare -r -a _k8s_node_hostname=(${_k8s_master_hostname[*]} ${_k8s_worker_hostname[*]})

# 定义浮动IP地址
declare -r    _k8s_virtual_ip="${_ip_prefix}.10"
# 获取外部浮动IP地址
declare -r    _k8s_virtual_fip=`cat /etc/VFIP||echo "127.0.0.1"`
ccat <<-EOF
============脚本信息============
path: ${_self_path}
 dir: ${_self_dir}
base: ${_self_base}
name: ${_self_name}
 ext: ${_self_ext}

============环境变量============
DOCKER_VERSION:         ${DOCKER_VERSION}
K8S_VERSION:            ${K8S_VERSION}
HOSTNAME:               ${HOSTNAME}
K8S_CP_PORT:            ${K8S_CP_PORT}
K8S_CLUSTER_NAME:       ${K8S_CLUSTER_NAME}
K8S_POD_CIDR:           ${K8S_POD_CIDR}
K8S_SVC_CIDR:           ${K8S_SVC_CIDR}
K8S_CNI:                ${K8S_CNI}
K8S_LB:                 ${K8S_LB}
K8S_LB_SVC_EIP_RANGE:   ${K8S_LB_SVC_EIP_RANGE}
K8S_IPVLAN_CIDR:        ${K8S_IPVLAN_CIDR}
K8S_IPVLAN_GATEWAY:     ${K8S_IPVLAN_GATEWAY}
K8S_IPVLAN_RANGE_START: ${K8S_IPVLAN_RANGE_START}
K8S_IPVLAN_RANGE_END:   ${K8S_IPVLAN_RANGE_END}

============网络信息============
默认网卡: ${_default_ifname}
默认IP:   ${_default_ip}
默认掩码: ${_default_netmask}

CIDR:     ${_default_cidr}
可用地址: ${_cidr_ip_nums}
起始地址: $(ip2str $_cidr_first_ip)
结束地址: $(ip2str $_cidr_last_ip)
子网掩码: $(ip2str $_cidr_netmask)
网络地址: $(ip2str $_cidr_ip)
广播地址: $(ip2str $_cidr_broadcast)

================================
_k8s_master: ${_k8s_master[*]}
_k8s_worker: ${_k8s_worker[*]}
_k8s_master_hostname: ${_k8s_master_hostname[*]}
_k8s_worker_hostname: ${_k8s_worker_hostname[*]}
_k8s_virtual_ip:  ${_k8s_virtual_ip}
_k8s_virtual_fip: ${_k8s_virtual_fip}
_k8s_cp_endpoint: ${_k8s_cp_endpoint}
EOF

if [ "$0" == "bash" ]; then
    # 可能是通过管道运行的
    input='Y'
else
    read -n1 -p "Are you sure to create a new kubernetes cluster? [y/N]" input
fi

#if [ 1 == 0 ]; then
if [ -z "$input" ]; then
    warn "Abort operation!" && exit 0
fi
echo '' 
case $input in
    Y|y)
        info "Continue...."
        ;;
    N|n)
        warn "Abort operation!" && exit 0
        ;;
    *)
        error "Invalid input!" && exit -1
        ;;
esac

# 初始化hosts文件
function init_hosts(){
    declare -r _file_hosts="/etc/hosts"
    
    info "generate '${_file_hosts}' to resolve the host name of each node..."

    echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > ${_file_hosts}
    echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> ${_file_hosts}
   
    for i in "${!_k8s_node[@]}"; do
        if grep -w "${_k8s_node[$i]}" "${_file_hosts}" > /dev/null 2>&1; then
            eval "sed -i '${_file_hosts}'-e '/\<${_k8s_node[$i]}\>/s/$/ ${_k8s_hostname_prefix}node-$[$i+1]/'"
        else
            echo "${_k8s_node[$i]} ${_k8s_hostname_prefix}node-$[$i+1]" >> "${_file_hosts}"
        fi
    done

    for i in "${!_k8s_master[@]}"; do
        if grep -w "${_k8s_master[$i]}" "${_file_hosts}" > /dev/null 2>&1; then
            eval "sed -i '${_file_hosts}' -e '/\<${_k8s_master[$i]}\>/s/$/ ${_k8s_master_hostname[$i]}/'"
        else
            echo "${_k8s_master[$i]} ${_k8s_master_hostname[$i]}" >> "${_file_hosts}"
        fi
    done

    for i in "${!_k8s_worker[@]}"; do
        if grep -w "${_k8s_worker[$i]}" "${_file_hosts}" > /dev/null 2>&1; then
            eval "sed -i '${_file_hosts}' -e '/\<${_k8s_worker[$i]}\>/s/$/ ${_k8s_worker_hostname[$i]}/'"
        else
            echo "${_k8s_worker[$i]} ${_k8s_worker_hostname[$i]}" >> "${_file_hosts}"
        fi
    done

    echo "${_k8s_virtual_ip} ${_k8s_hostname_prefix}master ${K8S_CLUSTER_NAME} ${K8S_CLUSTER_NAME}.yealink.top" >> "${_file_hosts}"
    cat "${_file_hosts}"
}

if [ 1 -eq 0 ]; then
# k8s环境初始化
source <(${CURL} http://mirrors.yealink.top/scripts/kubernetes/deploy/init-k8s-env.sh)
init_hosts
# 生成 SSH 密钥对
create_ssh_keypair
# 禁用严格的密钥检查
disable_strict_host_key_checking
#disable_strict_host_key_checking ${_k8s_node}
# 清除已知的主机签名信息缓存
clean_known_hosts

# 上传密钥（首次需要手工输入密码）
for i in "${!_k8s_node[@]}"; do ssh-copy-id ${_k8s_node[$i]}; done

# 初始化所有节点的k8s环境
for i in "${!_k8s_node[@]}"; do
    declare _host=${_k8s_node[$i]}
    info "${_host}: Copy files"
    scp /etc/hosts ${_host}:/etc/hosts
    scp -r /root/.ssh ${_host}:/root/
    ssh -Tq $_host <<-SSH
echo "====Run on host:${_host}===="
HOSTNAME=${_k8s_node_hostname[$i]}
K8S_VERSION=${K8S_VERSION}
_k8s_virtual_ip="${_k8s_virtual_ip}"
source <(${CURL} http://mirrors.yealink.top/scripts/kubernetes/deploy/init-k8s-env.sh)
if [ -d "${ETCD_DATA_DIR}" ]; then rm -rf "${ETCD_DATA_DIR}"||true; fi
# 当k8s的版本号大于v1.22时，对于coredns的镜像路径需要特殊处理一下
function version_ge() { test "\$(echo "\$@" | tr " " "\n" | sort -rV | head -n 1)" == "\$1"; }
if version_ge "${K8S_VERSION}" "1.22"; then
    COREDNS_VERSION=`kubeadm config images list --kubernetes-version=${K8S_VERSION}|grep coredns|awk -F: '{print $2}'`
    docker pull k8sgcr.yealink.top/coredns/coredns:\${COREDNS_VERSION}
    docker tag k8sgcr.yealink.top/coredns/coredns:\${COREDNS_VERSION} k8sgcr.yealink.top/coredns:\${COREDNS_VERSION}
fi
SSH
done

[ ${_k8s_init_only} -ne 0 ] && info "Done" && exit 0

# 部署首个控制节点
declare -r _token=`kubeadm token generate`
declare -r _cert_key=`kubeadm certs certificate-key`
ccat <<-EOF
token: ${_token}
certificate-key: ${_cert_key}
EOF

cat > /tmp/kubeadm-init.yaml <<-EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: ${_token}
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
certificateKey: "${_cert_key}"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
imageRepository: k8sgcr.yealink.top
kubernetesVersion: ${K8S_VERSION}
clusterName: "${K8S_CLUSTER_NAME}"
apiServer:
  certSANs:
  - "${_k8s_hostname_prefix}master"
  - "${_k8s_virtual_ip}"
  - "${_k8s_virtual_fip}"
  - "${K8S_CLUSTER_NAME}"
  - "${K8S_CLUSTER_NAME}.yealink.top"
controlPlaneEndpoint: "${_k8s_cp_endpoint}"
etcd:
  local:
    dataDir: "${ETCD_DATA_DIR}"
networking:
  podSubnet: ${K8S_POD_CIDR}
  serviceSubnet: ${K8S_SVC_CIDR}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
EOF

scp /tmp/kubeadm-init.yaml ${_k8s_master[0]}:/tmp/kubeadm-init.yaml

ssh -Tq ${_k8s_master[0]} <<-SSH
docker run --network host --rm ghcr.yealink.top/kube-vip/kube-vip:${KUBE_VIP_VERSION} manifest pod \
    --interface ${_default_ifname} \
    --vip ${_k8s_virtual_ip} \
    --cidr ${_default_netmask} \
    --controlplane \
    --services \
    --arp \
    --leaderElection \
| sed -e 's|ghcr.io|ghcr.yealink.top|g' \
| tee /etc/kubernetes/manifests/kube-vip.yaml

# 忽略 swap 启用警告
kubeadm init --config /tmp/kubeadm-init.yaml --upload-certs --ignore-preflight-errors=Swap
SSH

# 备份集群配置文件
if [ "${_default_ip}" != "${_k8s_master[0]}" ]; then
    scp    ${_k8s_master[0]}:/etc/kubernetes/admin.conf /etc/kubernetes/admin.conf
    scp -r ${_k8s_master[0]}:/etc/kubernetes/pki        /etc/kubernetes/
fi
#export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

declare -r _ca_cert_hash=`openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | openssl dgst -sha256 -hex|awk '{print $2}'`

# 其它 Master 节点加入
for i in "${!_k8s_master[@]}"; do
    if [ $i -eq 0 ]; then continue; fi
    ssh -Tq ${_k8s_master[$i]} <<-SSH
    kubeadm join ${_k8s_cp_endpoint} --token ${_token} \
    --discovery-token-ca-cert-hash sha256:${_ca_cert_hash} \
    --control-plane \
    --certificate-key=${_cert_key} \
    --ignore-preflight-errors=Swap
SSH
done

# 解决controller-manager和scheduler状态为Unhealthy的问题
# 新版已没有这个问题了
#for i in "${!_k8s_master[@]}"; do ssh -Tq ${_k8s_master[$i]} <<-'SSH'
#sed -i -e '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
#sed -i -e '/--port=0/d' /etc/kubernetes/manifests/kube-controller-manager.yaml
#SSH
#done

# 工作节点接入
for i in "${!_k8s_worker[@]}"; do
    ssh -Tq ${_k8s_worker[$i]} <<-SSH
    kubeadm join ${_k8s_cp_endpoint} --token ${_token} \
    --discovery-token-ca-cert-hash sha256:${_ca_cert_hash} \
    --ignore-preflight-errors=Swap
SSH
done

# 其它 Master 节点加入VIP
for i in "${!_k8s_master[@]}"; do
    if [ $i -eq 0 ]; then continue; fi
    ssh -Tq ${_k8s_master[$i]} <<-SSH
    docker run --network host --rm ghcr.yealink.top/kube-vip/kube-vip:${KUBE_VIP_VERSION} manifest pod \
    --interface ${_default_ifname} \
    --vip ${_k8s_virtual_ip} \
    --cidr ${_default_netmask} \
    --controlplane \
    --services \
    --arp \
    --leaderElection \
    | sed -e 's|ghcr.io|ghcr.yealink.top|g' \
    | tee /etc/kubernetes/manifests/kube-vip.yaml
SSH
done

# 如果工作节点小于3
if [ ${#_k8s_worker[*]} -lt 3 ]; then
    info "允许所有节点作为计算节点"
    kubectl taint node -l node-role.kubernetes.io/master= node-role.kubernetes.io/master- || true
fi

fi  ###########

case ${K8S_CNI} in
    "flannel")
        ${CURL} https://gitcode.yealink.com/open_source/mirror/flannel-io/flannel/-/raw/v0.14.0/Documentation/kube-flannel.yml \
            | sed -e "s|\<10\.244\.0\.0/16\>|${K8S_POD_CIDR}|g" -e "s|\<quay\.io\>|quay.yealink.top|g" \
            | kubectl apply -f -

            # 等待 flannel 部署完成
            kubectl -n kube-system rollout status daemonset kube-flannel-ds
        ;;
    "calico")
        ${CURL} https://docs.projectcalico.org/manifests/calico.yaml \
            | sed -e 's|\<docker\.io\>|docker.yealink.top|g' \
            | kubectl apply -f -

            # 等待 calico 部署完毕
            kubectl -n kube-system rollout status deployment calico-kube-controllers
            kubectl -n kube-system rollout status daemonset calico-node
        ;;
    "kubeovn")
        declare pod_gateway=`get_cidr_first_addr "${K8S_POD_CIDR}"`
        ${CURL} https://gitcode.yealink.com/open_source/mirror/kubeovn/kube-ovn/-/raw/v1.9.1/dist/images/install.sh \
            | sed -e "s|\<10\.16\.0\.0/16\>|${K8S_POD_CIDR}|g" \
                  -e "s|\<10\.96\.0\.0/12\>|${K8S_SVC_CIDR}|g" \
                  -e "s|\<10\.16\.0\.1\>|${pod_gateway}|g" \
            | bash
        ;;
    "ipvlan")
        declare -r _ip2_prefix=`echo ${_default_ip}|awk -F. '{printf "%d.%d.%d",$1,$2,$3}'`
        for i in "${!_k8s_node[@]}"; do ssh -Tq ${_k8s_node[$i]} <<-CMD
            cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<-EOF
BOOTPROTO=dhcp
DEVICE=eth1
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no
IPV6INIT=no
EOF
            ifdown eth1 || true
            ifup eth1
CMD
        done

        # 从github中检索最新stable版本号
        REPO="k8snetworkplumbingwg/whereabouts"
        VERSION="v0.5.1-ipvlan"

        #URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/doc/crds"
        URL="https://gitcode.yealink.com/open_source/mirror/${REPO}/-/raw/${VERSION}/doc/crds"

        # 部署 whereabouts
        kubectl apply -f "${URL}/whereabouts.cni.cncf.io_ippools.yaml" \
                      -f "${URL}/whereabouts.cni.cncf.io_overlappingrangeipreservations.yaml"
        ${CURL} "${URL}/daemonset-install.yaml" | sed -e "s|\<ghcr\.io\>.*|yealink.top/iaas/whereabouts:${VERSION}|g" | kubectl apply -f -
        #${CURL} "${URL}/ip-reconciler-job.yaml" | sed -e 's|\<ghcr\.io\>|ghcr.yealink.top|g' | kubectl apply -f -

        # 等待部署完毕
        kubectl -n kube-system rollout status daemonset whereabouts

        cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ipvlan-cni-config
  namespace: kube-system
data:
  10-ipvlan.conf: |
    {
      "cniVersion":"0.3.1",
      "name": "ipvlannet",
      "type": "ipvlan",
      "master": "eth1",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "${K8S_IPVLAN_CIDR}",
        "range_start": "${K8S_IPVLAN_RANGE_START}",
        "range_end": "${K8S_IPVLAN_RANGE_END}",
        "routes": [
          { "dst": "0.0.0.0/0", "gw": "${K8S_IPVLAN_GATEWAY}" },
          { "dst": "${K8S_SVC_CIDR}" },
          { "dst": "${K8S_NODELOCALDNS_IP}/32" }
        ]
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ipvlan-cni
  namespace: kube-system
  labels:
    tier: node
    app: ipvlan-cni
spec:
  selector:
    matchLabels:
      name: ipvlan-cni
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        tier: node
        app: ipvlan-cni
        name: ipvlan-cni
    spec:
      hostNetwork: true      
      nodeSelector:
        beta.kubernetes.io/arch: amd64
      tolerations:
      - operator: Exists
        effect: NoSchedule
      containers:
      - name: ipvlan-cni
        image: cr.yealinkops.com/iaas/ipvlan-cni:0.2.3
        imagePullPolicy: Always
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: true
        volumeMounts:
        - name: host-cni-net-dir
          mountPath: /host/etc/cni/net.d/
        - name: ipvlan-cni-config
          mountPath: /etc/cni/net.d/
      volumes:
        - name: host-cni-net-dir
          hostPath:
            path: /etc/cni/net.d/
        - name: ipvlan-cni-config
          configMap:
            name: ipvlan-cni-config
EOF
        ;;

    "none")
        ;;
    *)
        error "invalid net-type \"${K8S_CNI}\"" && exit 1
        ;;
esac


case ${K8S_LB} in
    "kubevip")
        REPO="kube-vip/kube-vip"
        VERSION="${KUBE_VIP_VERSION}"
        URL="https://gitcode.yealink.com/open_source/mirror/${REPO}/-/raw/${VERSION}/docs/manifests"

        # e3: 修复kubevip ClusterRole定义中的一个bug
        ${CURL} "${URL}/kube-vip-arp.yaml" \
            | sed -e "s|ghcr.io/kube-vip/kube-vip:.*|ghcr.yealink.top/kube-vip/kube-vip:${VERSION}|g" \
                  -e 's|ens160|eth0|g' \
                  -e 's|resources: \["services"\]|resources: \["services", "services/status", "nodes"\]|g' \
            | kubectl apply -f -

        REPO="kube-vip/kube-vip-cloud-provider"
        VERSION="main"
        URL="https://gitcode.yealink.com/open_source/mirror/${REPO}/-/raw/${VERSION}/manifest"
        ${CURL} "${URL}/kube-vip-cloud-controller.yaml" \
            | sed -e "s|kubevip/kube-vip-cloud-provider:.*|yealink.top/kube-vip/kube-vip-cloud-provider:0.2|g" \
            | kubectl apply -f -
        cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevip
  namespace: kube-system
data:
  range-global: ${K8S_LB_SVC_EIP_RANGE}
EOF
#       kubectl create configmap --namespace kube-system kubevip --from-literal range-global=${K8S_LB_SVC_EIP_RANGE}

        # 等待 kubevip 部署完成
        kubectl -n kube-system rollout status statefulset kube-vip-cloud-provider 
        kubectl -n kube-system rollout status deployment kube-vip-workers
        ;;
    "metallb")
        kubectl apply -f https://gitcode.yealink.com/open_source/mirror/metallb/metallb/-/raw/v0.10.2/manifests/namespace.yaml
        ${curl} https://gitcode.yealink.com/open_source/mirror/metallb/metallb/-/raw/v0.10.2/manifests/metallb.yaml \
            | sed -e 's/quay.io/quay.yealink.top/g' \
            | kubectl apply -f -

        cat <<-EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: my-ip-space
      protocol: layer2
      addresses:
      - ${K8S_LB_SVC_EIP_RANGE}
EOF

        if [ "${METALLB_CTRLER_IN_CP}" == "true" ]; then
            # 允许并限定metallb controller只能运行在控制节点上
            cat > /tmp/metallb-patch.yaml <<-'EOF'
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/os: linux
        node-role.kubernetes.io/control-plane: ""
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"            
EOF
            kubectl -n metallb-system patch deployment controller --patch-file /tmp/metallb-patch.yaml
        fi

        # 等待 metallb 部署完成
        kubectl -n metallb-system rollout status deployment controller
        kubectl -n metallb-system rollout status daemonset speaker
        ;;
    "none")
        ;;
    *)
        error "Invalid LoadBalancer Type: ${COLOR_PURPLE}${K8S_LB}" && exit 1
        ;;
esac

# 等待 coredns 准备就绪
#kubectl -n kube-system rollout status deployment coredns
# 等待 kube-proxy 准备就绪
#kubectl -n kube-system rollout status daemonset  kube-proxy

declare _dashboard_eip=''
# 安装 Dashboard
REPO="kubernetes/dashboard"
VERSION="v2.5.1"
URL="https://gitcode.yealink.com/open_source/mirror/${REPO}/-/raw/${VERSION}/aio/deploy"
kubectl apply -f "${URL}/recommended.yaml"
# 等待 Dashboard 部署完成
kubectl -n kubernetes-dashboard rollout status deployment kubernetes-dashboard
if [ "${K8S_LB}" != "none" ]; then
    # 调整 Dashboard 的外部访问方式为 LoadBalancer 方式
    kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

    # 等待EIP就绪
    _dashboard_eip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}` || true
    echo -e "Wait for loadbalancer service 'kubernetes-dashboard' to get the external-ip.\c"
    while ! echo "${_dashboard_eip}"|grep -Ewq "${REGEX_IPV4}"; do
        echo -e ".\c"
        sleep 1s
        _dashboard_eip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}` || true
    done
    echo -e "......\c" && info "[READY]"    
else
    # 调整 Dashboard 的外部访问方式为 NodePort 方式
    kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'
fi
# 创建管理员帐号
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 生成快速获得dashboard令牌的脚本
cat > /usr/local/bin/kubectl-dashboard-token <<-'EOF'
#!/bin/bash
set -euo pipefail
ACCOUNT="dashboard-admin"
SECRET=`kubectl -n kube-system get ServiceAccount ${ACCOUNT} -o jsonpath={.secrets[*].name}`
TOKEN=`kubectl -n kube-system get secrets ${SECRET} -o jsonpath={.data.token}|base64 -d`
echo ${TOKEN}
EOF
chmod +x /usr/local/bin/kubectl-dashboard-token 

# 测试
cat <<-'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: php-nginx
data:
  index.php: |
    <!DOCTYPE HTML><html><head><meta charset="utf-8"/><title>Test Page</title></head><body>
    <?php date_default_timezone_set('PRC'); ?>
    <h1>Now：<?=date('Y-m-d H:i:s')?></h1><hr/>
    <h1>Server Information:</h1>
    <h2>Host Name: <?=gethostname()?></h2>
    <h2>IP Address: <?=$_SERVER['SERVER_ADDR']?></h2>
    <h2>Port: <?=$_SERVER['SERVER_PORT']?></h2><hr/>
    <h1>HTTP Information:</h1>
    <h2>Host: <?=$_SERVER["HTTP_HOST"]?></h2>
    <h2>REMOTE_ADDR: <?=$_SERVER["REMOTE_ADDR"]?></h2>
    <h2>HTTP_CLIENT_IP: <?=$_SERVER["HTTP_CLIENT_IP"]?></h2>
    <h2>HTTP_X_FORWARDED_FOR: <?=$_SERVER["HTTP_X_FORWARDED_FOR"]?></h2>
    </body></html>
---
apiVersion:  apps/v1
kind: Deployment
metadata:
  name: php-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: php-nginx
  template:
    metadata:
      labels:
        app: php-nginx
    spec:
      containers:
      - name: php-nginx
        image: yealink.top/webdevops/php-nginx:7.4-alpine
        volumeMounts:
        - name: index
          mountPath: "/app/"
          readOnly: true
      volumes:
      - name: index
        configMap:
          name: php-nginx
EOF


# 等待 deployment 进入 ready状态 
kubectl rollout status deployment php-nginx
kubectl delete svc php-nginx||true

declare _nginx_eip=''

if [ "${K8S_LB}" != "none" ]; then
    # 创建 LoadBalancer 类型的Service
    kubectl expose deployment php-nginx --port=80 --type=LoadBalancer
    #kubectl create svc loadbalancer php-nginx --tcp=80:80

    # 等待EIP就绪
    _nginx_eip=`kubectl get svc php-nginx --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}` || true
    echo -e "Wait for loadbalancer service 'php-nginx' to get the external-ip.\c"
    while ! echo "${_nginx_eip}"|grep -Ewq "${REGEX_IPV4}"; do
        echo -e ".\c"
        sleep 1s
        _nginx_eip=`kubectl get svc php-nginx --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}` || true
    done
    echo -e "......\c" && info "[READY]"  
else
    # 创建 NodePort 类型的 Service
    kubectl expose deployment php-nginx --port=80 --type=NodePort
    #kubectl create service nodeport php-nginx --tcp=80:80
fi

kubectl get pods,svc -A -o wide


#fi
#_dashboard_eip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
#_nginx_eip=`kubectl get svc php-nginx --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
#echo ""

declare -r _dashboard_cluster_ip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.spec.clusterIP}`
declare -r _dashboard_port=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.spec.ports[*].port}`
declare -r _dashboard_nodeport=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.spec.ports[*].nodePort}`


ccat <<-EOF
dashboard url: https://${_dashboard_cluster_ip}:${_dashboard_port}
EOF

echo -e "${COLOR_PURPLE}\c"
if [ "${K8S_LB}" != "none" ]; then cat <<-EOF
               https://${_dashboard_eip}:${_dashboard_port}
EOF
    if [ "${K8S_LB}" == "kubevip" ]; then cat <<-EOF
               https://${_dashboard_eip}:${_dashboard_nodeport}
EOF
    fi
fi

cat <<-EOF
               https://${_k8s_virtual_ip}:${_dashboard_nodeport}
               https://${_k8s_virtual_fip}:${_dashboard_nodeport}
               https://${K8S_CLUSTER_NAME}.yealink.top:${_dashboard_nodeport}
EOF

for i in "${!_k8s_node[@]}"; do cat <<-EOF
               http://${_k8s_node[$i]}:${_dashboard_nodeport}
EOF
done
echo -e "${COLOR_DEFAULT}"

ccat <<-EOF
dashboard token: $(kubectl dashboard token)
EOF

declare -r _nginx_cluster_ip=`kubectl get svc php-nginx --no-headers -o jsonpath={.spec.clusterIP}`
declare -r _nginx_port=`kubectl get svc php-nginx --no-headers -o jsonpath={.spec.ports[*].port}`
declare -r _nginx_nodeport=`kubectl get svc php-nginx --no-headers -o jsonpath={.spec.ports[*].nodePort}`

echo ""

ccat <<-EOF
php-nginx url: http://${_nginx_cluster_ip}:${_nginx_port}
EOF
echo -e "${COLOR_PURPLE}\c"
if [ "${K8S_LB}" != "none" ]; then cat <<-EOF
               http://${_nginx_eip}:${_nginx_port}
EOF
    if [ "${K8S_LB}" == "kubevip" ]; then cat <<-EOF
               http://${_nginx_eip}:${_nginx_nodeport}
EOF
    fi
fi
cat <<-EOF
               http://${_k8s_virtual_ip}:${_nginx_nodeport}
               http://${_k8s_virtual_fip}:${_nginx_nodeport}
               http://${K8S_CLUSTER_NAME}.yealink.top:${_nginx_nodeport}
EOF

for i in "${!_k8s_node[@]}"; do cat <<-EOF
               http://${_k8s_node[$i]}:${_nginx_nodeport}
EOF
done
echo -e "${COLOR_DEFAULT}"

info "Done" && exit 

