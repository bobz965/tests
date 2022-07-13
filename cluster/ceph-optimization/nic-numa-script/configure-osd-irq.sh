#!/bin/bash
irq_list=(`cat /proc/interrupts | grep osd | awk -F: '{print $1}'`)
cpunum=64  # 修改为所在node的第一个Core
for irq in ${irq_list[@]}
do
echo $cpunum > /proc/irq/$irq/smp_affinity_list
echo `cat /proc/irq/$irq/smp_affinity_list`
(( cpunum+=2 ))
done
