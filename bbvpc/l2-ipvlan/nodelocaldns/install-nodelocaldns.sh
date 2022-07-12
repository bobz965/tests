#!/bin/bash
set -exuo pipefail

CURL='curl -s -L'
K8S_VERSION=`kubectl version --short=true|grep Server|awk '{print $3}'`
K8S_SVC_CLUSTER_IP=`kubectl -n kube-system get svc kube-dns -ojsonpath={.spec.clusterIP}`
K8S_CLUSTER_DOMAIN=`kubectl -n kube-system get cm kubelet-config-${KSS_VERSION_SHORT} -o jsonpath={.data.kubelet}|grep clusterDomain|awk '{printf $2}'`
K8S_NODELOCALDNS_IP="169.254.20.10"

echo "K8S_VERSION=${K8S_VERSION}"
echo "K8S_SVC_CLUSTER_IP=${K8S_SVC_CLUSTER_IP}"
echo "K8S_CLUSTER_DOMAIN=${K8S_CLUSTER_DOMAIN}"
echo "K8S_NODELOCALDNS_IP=${K8S_NODELOCALDNS_IP}"

${CURL} https://gitcode.yealink.com/open_source/mirror/kubernetes/kubernetes/-/raw/${K8S_VERSION}/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml \
    | sed -e 's/k8s.gcr.io/k8sgcr.yealink.top/g' \
          -e "s/__PILLAR__DNS__SERVER__/${K8S_SVC_CLUSTER_IP}/g" \
          -e 's/__PILLAR__LOCAL__DNS__/${K8S_NODELOCALDNS_IP}/g' \
          -e "s/__PILLAR__DNS__DOMAIN__/${K8S_CLUSTER_DOMAIN}/g" \
    | kubectl apply -f -

for i in `kubectl get no -ojsonpath={.items[*].metadata.name}`;do echo $i; ssh -Tq $i <<-CMD
    sed -e "s/${K8S_SVC_CLUSTER_IP}/${K8S_NODELOCALDNS_IP}/g" -i /var/lib/kubelet/config.yaml
    systemctl daemon-reload && systemctl restart kubelet
CMD
done
