# cd ..
# copy 脚本并执行

#ln -s kube-ovn-self-ci/001-build-ubuntu-base.sh 001-build-ubuntu-base.sh
ln -s kube-ovn-self-ci/002-build-l1-kube-ovn-base.sh 002-build-l1-kube-ovn-base.sh
ln -s kube-ovn-self-ci/003-build-l1-kube-ovn-controller.sh 003-build-l1-kube-ovn-controller.sh
ln -s kube-ovn-self-ci/004-build-vpc-nat-gateway.sh 004-build-vpc-nat-gateway.sh
#ln -s kube-ovn-self-ci/01-ubuntu-base-docker-file 01-ubuntu-base-docker-file
ln -s kube-ovn-self-ci/02-l1-kube-ovn-base-dockerfile 02-l1-kube-ovn-base-dockerfile
ln -s kube-ovn-self-ci/03-l1-kube-ovn-controller-dockerfile 03-l1-kube-ovn-controller-dockerfile
ln -s kube-ovn-self-ci/04-vpc-nat-gateway-docker-file 04-vpc-nat-gateway-docker-file
ln -s kube-ovn-self-ci/release.rc release.rc


rm -f 001-build-ubuntu-base.sh 002-build-l1-kube-ovn-base.sh 003-build-l1-kube-ovn-controller.sh 004-build-vpc-nat-gateway.sh 01-ubuntu-base-docker-file 02-l1-kube-ovn-base-dockerfile 03-l1-kube-ovn-controller-dockerfile 04-vpc-nat-gateway-docker-file release.rc
