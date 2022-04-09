source ./release.rc
src_image=kubeovn/vpc-nat-gateway:v1.10.0
url=registry.yealinkops.com/third_party/kolla
registry_tag="$url/vpc-nat-gateway:$release"
docker tag $src_image   $registry_tag
docker push $registry_tag

# clean image
# docker image prune  -a -f
# docker rmi $(docker images -f "dangling=true" -q) -f
