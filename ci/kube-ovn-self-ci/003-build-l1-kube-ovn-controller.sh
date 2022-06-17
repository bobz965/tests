source ./release.rc
name=l1-kube-ovn-controller
image=$name
echo "ready to build base image: $image:$release"
docker build --network=host -t $image:$release -f 03-l1-kube-ovn-controller-dockerfile .

url=registry.yealinkops.com/third_party/kolla

line=`docker images | grep $image | grep $release`


num=`echo $line | wc -l`
if [ "$num" != "1" ];then
      echo "匹配到的镜像数目不是1"
      exit 0
fi
with_nsname=`echo $line |awk -F' ' '{print $1}'`	
tag=`echo $line |awk -F' ' '{print $2}'`
tag_image="$with_nsname:$tag"
registry_tag="$url/$image:$release"
echo "tag $tag_image --> $registry_tag ..."
docker tag $tag_image   $registry_tag
echo "ready to push $registry_tag ..."
docker push $registry_tag

# clean image

# docker image prune  -a -f
# docker rmi $(docker images -f "dangling=true" -q) -f
