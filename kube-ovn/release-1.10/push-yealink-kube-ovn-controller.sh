source ./release.rc
src_image=kubeovn/kube-ovn:v1.10.0
url=registry.yealinkops.com/third_party/kolla
registry_tag="$url/kube-ovn:$release"
docker tag $src_image   $registry_tag
docker push $registry_tag

# clean image
# docker image prune  -a -f
# docker rmi $(docker images -f "dangling=true" -q) -f
