# hci-rbd 目前只有三个节点 
# 2个cpu核心 对应两个numa nodes 编号 0 1 
## Socket 0: 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78
## Socket 1: 1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59 61 63 65 67 69 71 73 75 77 79
# 每个 node 
## hdd osd 8
## nvme osd 14

#根据ceph osd df tree 的list 出的osd的顺序 将node上的hdd nvme osd 平均分配到两个numa nodes

# node1
## 4 hdd osds to numa node 0
ceph config set osd.1 osd_numa_node 0
ceph config set osd.4 osd_numa_node 0
ceph config set osd.7 osd_numa_node 0
ceph config set osd.10 osd_numa_node 0

## 4 hdd osds to numa node 1
ceph config set osd.14 osd_numa_node 1
ceph config set osd.17 osd_numa_node 1
ceph config set osd.20 osd_numa_node 1
ceph config set osd.23 osd_numa_node 1


## 7 nvme osds to numa node 0
ceph config set osd.25 osd_numa_node 0
ceph config set osd.27 osd_numa_node 0
ceph config set osd.30 osd_numa_node 0
ceph config set osd.33 osd_numa_node 0
ceph config set osd.36 osd_numa_node 0
ceph config set osd.39 osd_numa_node 0
ceph config set osd.42 osd_numa_node 0

## 7 nvme osds to numa node 1
ceph config set osd.45 osd_numa_node 1
ceph config set osd.48 osd_numa_node 1
ceph config set osd.51 osd_numa_node 1
ceph config set osd.54 osd_numa_node 1
ceph config set osd.57 osd_numa_node 1
ceph config set osd.60 osd_numa_node 1
ceph config set osd.63 osd_numa_node 1

# node2
## 4 hdd osds to numa node 0
ceph config set osd.0 osd_numa_node 0
ceph config set osd.3 osd_numa_node 0
ceph config set osd.6 osd_numa_node 0
ceph config set osd.9 osd_numa_node 0

## 4 hdd osds to numa node 1
ceph config set osd.12 osd_numa_node 1
ceph config set osd.15 osd_numa_node 1
ceph config set osd.18 osd_numa_node 1
ceph config set osd.21 osd_numa_node 1


## 7 nvme osds to numa node 0
ceph config set osd.26 osd_numa_node 0
ceph config set osd.28 osd_numa_node 0
ceph config set osd.31 osd_numa_node 0
ceph config set osd.34 osd_numa_node 0
ceph config set osd.37 osd_numa_node 0
ceph config set osd.40 osd_numa_node 0
ceph config set osd.43 osd_numa_node 0

## 7 nvme osds to numa node 1
ceph config set osd.46 osd_numa_node 1
ceph config set osd.49 osd_numa_node 1
ceph config set osd.52 osd_numa_node 1
ceph config set osd.55 osd_numa_node 1
ceph config set osd.58 osd_numa_node 1
ceph config set osd.61 osd_numa_node 1
ceph config set osd.64 osd_numa_node 1

# node3
## 4 hdd osds to numa node 0
ceph config set osd.2 osd_numa_node 0
ceph config set osd.5 osd_numa_node 0
ceph config set osd.8 osd_numa_node 0
ceph config set osd.11 osd_numa_node 0

## 4 hdd osds to numa node 1
ceph config set osd.13 osd_numa_node 1
ceph config set osd.16 osd_numa_node 1
ceph config set osd.19 osd_numa_node 1
ceph config set osd.22 osd_numa_node 1

## 7 nvme osds to numa node 0
ceph config set osd.24 osd_numa_node 0
ceph config set osd.29 osd_numa_node 0
ceph config set osd.32 osd_numa_node 0
ceph config set osd.35 osd_numa_node 0
ceph config set osd.38 osd_numa_node 0
ceph config set osd.41 osd_numa_node 0
ceph config set osd.44 osd_numa_node 0

## 7 nvme osds to numa node 1
ceph config set osd.47 osd_numa_node 1
ceph config set osd.50 osd_numa_node 1
ceph config set osd.53 osd_numa_node 1
ceph config set osd.56 osd_numa_node 1
ceph config set osd.59 osd_numa_node 1
ceph config set osd.62 osd_numa_node 1
ceph config set osd.65 osd_numa_node 1



# 重启
# for i in {0..65}; do ceph orch daemon restart osd.$i; done

# 观察 osd 已绑定到numa node
# watch -d -n 3 'ceph osd numa-status'





# ref: https://zhuanlan.zhihu.com/p/56102675



