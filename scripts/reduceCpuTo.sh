#!/bin/sh

nbCpu=48

while [ "$nbCpu" -ge "$1" ] 
do 
echo 0 > "/sys/devices/system/cpu/cpu"$nbCpu"/online"
nbCpu=`expr $nbCpu - 1`
done
