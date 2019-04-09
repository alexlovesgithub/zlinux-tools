#!/bin/sh

re='^[0-9]+$'
if ! [[ $1 =~ $re ]] ; then
   	echo "---> ERROR: You have to specify the number of IFL you want to get." >&2; exit 1
else
	cpt=1
	while [ "$cpt" -lt "$1" ] 
	do 
		echo 1 > "/sys/devices/system/cpu/cpu"$cpt"/online"
		cpt=`expr $cpt + 1`
	done
fi
