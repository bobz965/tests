#!/bin/bash
# 
#*************************************************************
# 作者：吴创豪
# 日期：2021/9/28
# 文件：deploy-k8s-allinone.sh
# 描述：部署一个单机版的 kubernetes 环境
# Usage: $0 [-n <cluster name>] [-c <CNI type>] [-b <LB type>] [-h|-?]
#    -n <cluster name>   Specify the cluster name. default is 'k8s-cluster'.
#    -c <CNI type>       Specify the CNI type. Can be [none|flannel|calico|kubeovn], default is 'none'.
#    -h|-?               pring usage
#*************************************************************

# set命令参数说明:
# -e 若指令传回值不等于0，则立即退出shell
# -u 当执行时使用到未定义过的变量，则显示错误信息
# -o 找开特殊选项
# -o pipefail 表示在管道连接的命令序列中，只要有任何一个命令返回非0值，则整个管道返回非0值
set -euo pipefail

# 设置主机名
HOSTNAME=${HOSTNAME:-}

# 使用指定版本的 docker
DOCKER_VERSION=${DOCKER_VERSION:-}

# 使用指定版本的 kubernetes
K8S_VERSION=${K8S_VERSION:-"1.21.0"}

# 定义apiserver的端口号
K8S_CP_PORT=${K8S_CP_PORT:-"6443"}

# 定义k8s集群名称
K8S_CLUSTER_NAME=${K8S_CLUSTER_NAME:-"kubernetes"}

# 定义pod子网CIDR
# 可用地址： 65534
# 起始地址： 172.24.0.1
# 结束地址： 172.24.255.254
# 子网掩码： 255.255.0.0
# 网络地址： 172.24.0.0
# 广播地址： 172.24.255.255
K8S_POD_CIDR="172.24.0.0/16"

# 定义service子网CIDR
# 可用地址： 262142
# 起始地址： 172.28.0.1
# 结束地址： 172.31.255.254
# 子网掩码： 255.252.0.0
# 网络地址： 172.28.0.0
# 广播地址： 172.31.255.255
K8S_SVC_CIDR="172.28.0.0/14"

# 定义要使用的cni插件名。支持 flannel、calico、kubeovn
K8S_CNI=${K8S_CNI:-"none"}

# 使用哪种 Load Balancer。支持 kubevip、metallb
K8S_LB=${K8S_LB:-"none"}

# 允许并限定metallb controller只能运行在控制节点上
METALLB_CTRLER_IN_CP=${METALLB_CTRLER_IN_CP:-"false"}

source <(curl -s http://yum.yealink.top/scripts/kubernetes/deploy/common.sh)

get_self
get_default_network
get_cidr_detail ${_default_cidr}
set_hostname

# 获取外部浮动IP地址
declare -r    _k8s_fip=`cat /etc/FIP||echo "127.0.0.1"`

# 获取IP地址的前三位
declare -r    _ip_prefix=`ip2str ${_cidr_ip}|awk -F. '{printf "%d.%d.%d",$1,$2,$3}'`

# 定义LB的IP地址可用范围
declare -r    _k8s_lb_ip_range="${_ip_prefix}.100-${_ip_prefix}.254"

# 定义控制平面地址
declare -l    _k8s_cp_endpoint="${K8S_CLUSTER_NAME}.yealink.top:${K8S_CP_PORT}"

# 只是初始化k8s集群环境，但并不实际部署k8s集群
declare -i    _k8s_init_only=0

function usage(){
   cat <<-EOF
Usage: $0 [-n <cluster name>] [-c <CNI type>] [-b <LB type> [-h|-?]
    -n <cluster name>   Specify the cluster name. default is 'k8s-cluster'.
    -c <CNI type>       Specify the CNI type. Can be [none|flannel|calico|kubeovn], default is 'none'.
    -b <LB type>        Specify the LoadBalancer type. Can be [kubevip|metallb], default is 'none'.
    -h|-?               pring usage
options:
    --init-only         Only initialize the k8s environment, but do not deploy the k8s cluster.
EOF
}

while getopts "n: c: b: :h? -:" opt; do
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
            if [ "${cni}" != "none" -a "${cni}" != "flannel" -a "${cni}" != "calico" -a "${cni}" != "kubeovn" ]; then
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
        h|?)
            usage && exit 0
            ;;
        *)
            usage && error "unknown command"  && exit 1
        ;;
    esac
done

ccat <<-EOF
============脚本信息============
path: ${_self_path}
 dir: ${_self_dir}
base: ${_self_base}
name: ${_self_name}
 ext: ${_self_ext}

============环境变量============
DOCKER_VERSION:   ${DOCKER_VERSION}
K8S_VERSION:      ${K8S_VERSION}
HOSTNAME:         ${HOSTNAME}
K8S_CP_PORT:      ${K8S_CP_PORT}
K8S_CLUSTER_NAME: ${K8S_CLUSTER_NAME}
K8S_POD_CIDR:     ${K8S_POD_CIDR}
K8S_SVC_CIDR:     ${K8S_SVC_CIDR}
K8S_CNI::         $K8S_CNI
K8S_LB:           ${K8S_LB}

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
_k8s_fip: ${_k8s_fip}
_k8s_lb_ip_range: ${_k8s_lb_ip_range}
_k8s_cp_endpoint: ${_k8s_cp_endpoint}
EOF

if [ "$0" == "bash" ]; then
    # 可能是通过管道运行的
    input='Y'
else
    read -n1 -p "Are you sure to create a new kubernetes cluster? [y/N]" input
fi

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

# k8s环境初始化
source <(curl -s http://yum.yealink.top/scripts/kubernetes/deploy/init-k8s-env.sh)

# 初始化hosts文件
function init_hosts() {
    declare -r _file_hosts="/etc/hosts"
    
    info "generate '${_file_hosts}' to resolve the host name of each node..."

    echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > ${_file_hosts}
    echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> ${_file_hosts}
    
    echo "${_default_ip} ${HOSTNAME} ${K8S_CLUSTER_NAME} ${K8S_CLUSTER_NAME}.yealink.top" >> "${_file_hosts}"
    cat "${_file_hosts}"
}

init_hosts

[ ${_k8s_init_only} -ne 0 ] && info "Done" && exit 0

cat > /tmp/kubeadm-init.yaml <<-EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
imageRepository: yealink.top/google_containers
kubernetesVersion: ${K8S_VERSION}
clusterName: "${K8S_CLUSTER_NAME}"
apiServer:
  certSANs:
  - "k8s-master"
  - "${_k8s_fip}"
  - "${K8S_CLUSTER_NAME}"
  - "${K8S_CLUSTER_NAME}.yealink.top"
controlPlaneEndpoint: "${_k8s_cp_endpoint}"
networking:
  podSubnet: ${K8S_POD_CIDR}
  serviceSubnet: ${K8S_SVC_CIDR}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
EOF

kubeadm init --config /tmp/kubeadm-init.yaml

#kubeadm init \
#--image-repository yealink.top/google_containers \
#--control-plane-endpoint=${_k8s_cp_endpoint} \
#--apiserver-cert-extra-sans=${K8S_CLUSTER_NAME} \
#--apiserver-cert-extra-sans=${_k8s_fip} \
#--pod-network-cidr=${K8S_POD_CIDR} \
#--service-cidr=${K8S_SVC_CIDR} \
#--kubernetes-version=${K8S_VERSION}

export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

info "解决controller-manager和scheduler状态为Unhealthy的问题"
sed -i -e '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
sed -i -e '/--port=0/d' /etc/kubernetes/manifests/kube-controller-manager.yaml

info "允许所有节点作为计算节点"
kubectl taint node --all node-role.kubernetes.io/master-

case ${K8S_CNI} in
    "flannel")
        curl -s https://gitcode.yealink.com/open_source/mirror/flannel-io/flannel/-/raw/v0.14.0/Documentation/kube-flannel.yml \
            | sed -e "s|\<10\.244\.0\.0/16\>|${K8S_POD_CIDR}|g" -e "s|\<quay\.io\>|yealink.top|g" \
            | kubectl apply -f -

            # 等待 flannel 部署完成
            kubectl -n kube-system rollout status daemonset kube-flannel-ds
        ;;
    "calico")
        curl -s https://docs.projectcalico.org/manifests/calico.yaml \
            | sed -e 's|\<docker\.io\>|yealink.top|g' \
            | kubectl apply -f -

            # 等待 calico 部署完毕
            kubectl -n kube-system rollout status deployment calico-kube-controllers
            kubectl -n kube-system rollout status daemonset calico-node
        ;;
    "kubeovn")
        declare pod_gateway=`get_cidr_first_addr "${K8S_POD_CIDR}"`
        #curl -s https://gitcode.yealink.com/open_source/mirror/kubeovn/kube-ovn/-/raw/v1.8.0/dist/images/install.sh \
        #    | sed -e "s|\<10\.16\.0\.0/16\>|${K8S_POD_CIDR}|g" \
        #          -e "s|\<10\.96\.0\.0/12\>|${K8S_SVC_CIDR}|g" \
        #          -e "s|\<10\.16\.0\.1\>|${pod_gateway}|g" \
        #    | bash
        # e5: 一级k8s的JOIN_CIDR也100.64.0.0/16，如果二级k8s的JOIN_CIDR也是这个值的话，将会造成物理机与虚拟机无法通信，所以要改掉。
        curl -s -L -x http://netproxy.yealinkops.com:8123 https://raw.githubusercontent.com/kubeovn/kube-ovn/v1.8.1/dist/images/install.sh \
            | sed -e "s|\<10\.16\.0\.0/16\>|${K8S_POD_CIDR}|g" \
                  -e "s|\<10\.96\.0\.0/12\>|${K8S_SVC_CIDR}|g" \
                  -e "s|\<10\.16\.0\.1\>|${pod_gateway}|g" \
                  -e 's|^VERSION=.*|VERSION="v1.8.2-x86"|g' \
                  -e 's|^JOIN_CIDR=.*|JOIN_CIDR="100.63.0.0/16"|g' \
            | bash
        ;;
    "none")
        ;;
    *)
        error "invalid net-type \"${K8S_CNI}\"" && exit 1
        ;;
esac

case ${K8S_LB} in
    "kubevip")
        # e3: 修复kubevip ClusterRole定义中的一个bug
        # e4: kubevip默认会创建3个副布，但我们是单节点模式，所以需要调整一下
        curl -s https://gitcode.yealink.com/open_source/mirror/kube-vip/kube-vip/-/raw/v0.3.8/docs/manifests/kube-vip-arp.yaml \
            | sed -e 's|ghcr.io/kube-vip/kube-vip:0.3.7|plndr/kube-vip:v0.3.8|g' \
                  -e 's|ens160|eth0|g' \
                  -e 's|resources: \["services"\]|resources: \["services", "services/status", "nodes"\]|g' \
                  -e 's|replicas: 3|replicas: 1|g' \
            | kubectl apply -f -

        curl -s https://gitcode.yealink.com/open_source/mirror/kube-vip/kube-vip-cloud-provider/-/raw/0.1/manifest/kube-vip-cloud-controller.yaml \
            | kubectl apply -f -

        kubectl create configmap --namespace kube-system kubevip --from-literal range-global=${_k8s_lb_ip_range}

        # 等待 kubevip 部署完成
        kubectl -n kube-system rollout status statefulset kube-vip-cloud-provider 
        kubectl -n kube-system rollout status deployment kube-vip-workers
        ;;
    "metallb")
        kubectl apply -f https://gitcode.yealink.com/open_source/mirror/metallb/metallb/-/raw/v0.10.2/manifests/namespace.yaml
        curl -s https://gitcode.yealink.com/open_source/mirror/metallb/metallb/-/raw/v0.10.2/manifests/metallb.yaml \
            | sed -e 's/quay.io/yealink.top/g' \
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
      - ${_k8s_lb_ip_range}
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
kubectl -n kube-system rollout status deployment coredns
# 等待 kube-proxy 准备就绪
kubectl -n kube-system rollout status daemonset  kube-proxy

declare _dashboard_eip=''
# 安装 Dashboard
kubectl apply -f https://gitcode.yealink.com/open_source/mirror/kubernetes/dashboard/-/raw/v2.3.1/aio/deploy/recommended.yaml
# 等待 Dashboard 部署完成
kubectl -n kubernetes-dashboard rollout status deployment kubernetes-dashboard
if [ "${K8S_LB}" != "none" ]; then
    # 调整 Dashboard 的外部访问方式为 LoadBalancer 方式
    kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

    # 等待EIP就绪
    _dashboard_eip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
    echo -e "Wait for loadbalancer service 'kubernetes-dashboard' to get the external-ip.\c"
    while ! echo "${_dashboard_eip}"|grep -Ewq "${REGEX_IPV4}"; do
        echo -e ".\c"
        sleep 1s
        _dashboard_eip=`kubectl -n kubernetes-dashboard get svc kubernetes-dashboard --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
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
    _nginx_eip=`kubectl get svc php-nginx --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
    echo -e "Wait for loadbalancer service 'php-nginx' to get the external-ip.\c"
    while ! echo "${_nginx_eip}"|grep -Ewq "${REGEX_IPV4}"; do
        echo -e ".\c"
        sleep 1s
        _nginx_eip=`kubectl get svc php-nginx --no-headers -o jsonpath={.status.loadBalancer.ingress[*].ip}`
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
               https://${_k8s_fip}:${_dashboard_nodeport}
               https://${K8S_CLUSTER_NAME}.yealink.top:${_dashboard_nodeport}
EOF

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
               http://${_k8s_fip}:${_nginx_nodeport}
               http://${K8S_CLUSTER_NAME}.yealink.top:${_nginx_nodeport}
EOF
echo -e "${COLOR_DEFAULT}"

info "Done" && exit 
