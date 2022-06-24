
``` bash


[root@hci-dev-mst-1 0617]# kubectl logs -f -n kube-system   kube-ovn-controller-b9fb94fdc-xn75d | grep -C 3 10.16.0.6
I0624 09:14:42.641826       6 ipam.go:79] allocate v4 10.16.0.10 mac 00:00:00:76:61:8A for kube-system/coredns-7f6f7d5658-xtfzf
I0624 09:14:42.641894       6 ipam.go:79] allocate v4 10.16.0.15 mac 00:00:00:01:E5:A7 for kube-system/kube-ovn-pinger-xrgqw
I0624 09:14:42.641967       6 ipam.go:79] allocate v4 192.168.3.4 mac 00:00:00:9E:05:69 for cjh2/pod-ovn-test
I0624 09:14:42.642036       6 ipam.go:79] allocate v4 10.16.0.6 mac 00:00:00:FD:93:C5 for default/static-ip
I0624 09:14:42.642085       6 ipam.go:79] allocate v4 10.16.0.14 mac 00:00:00:D5:00:30 for kube-system/kube-ovn-pinger-9mn4z
I0624 09:14:42.642166       6 ipam.go:79] allocate v4 10.16.0.18 mac 00:00:00:F3:54:3F for default/busybox02
I0624 09:14:42.642229       6 ipam.go:79] allocate v4 10.16.0.17 mac 00:00:00:67:72:F9 for kube-system/kube-ovn-pinger-zj6gj
I0624 09:14:42.642264       6 ipam.go:79] allocate v4 10.16.0.6 mac 00:00:00:FD:93:C5 for vip-dynamic-01
I0624 09:14:42.642326       6 ipam.go:79] allocate v4 100.64.0.3 mac 00:00:00:D8:45:A6 for node-hci-dev-mst-3
I0624 09:14:42.642360       6 ipam.go:79] allocate v4 100.64.0.4 mac 00:00:00:0D:5A:D0 for node-hci-dev-work-2
I0624 09:14:42.642395       6 ipam.go:79] allocate v4 100.64.0.5 mac 00:00:00:F8:24:64 for node-hci-dev-work-1




# 可以看到 10.16.0.6 出现两次，先ip 后vip， ipam功能判定，只要是ip被缓存，被占住就是正常的

I0624 09:14:42.642264       6 ipam.go:79] allocate v4 10.16.0.6 mac 00:00:00:FD:93:C5 for vip-dynamic-01
I0624 09:14:42.642036       6 ipam.go:79] allocate v4 10.16.0.6 mac 00:00:00:FD:93:C5 for default/static-ip



# 但是webhook发现有重复的ip

# 所以还是要过滤掉vip 的恢复


```
