#!/bin/bash
set -euo pipefail

for i in {1..6};do ssh k8s-node-$i <<-CMD
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<-EOF
BOOTPROTO=none
DEVICE=eth1
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no
IPV6INIT=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<-EOF
BOOTPROTO=none
DEVICE=eth2
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no
IPV6INIT=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth3 <<-EOF
BOOTPROTO=none
DEVICE=eth3
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no
IPV6INIT=no
EOF



ifup eth1
ifup eth2
ifup eth3
CMD
done
