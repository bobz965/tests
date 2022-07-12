#!/bin/bash
set -euo pipefail

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


ifdown eth1
ifdown eth2
ifdown eth3
ifup eth1
ifup eth2
ifup eth3
