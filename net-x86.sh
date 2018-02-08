#!/bin/bash

ifconfig eth2 > /dev/null 2>&1
err=$?
if [[ $err != 0 ]]; then
	echo "eth2 not found - are you using the right topology?" >&2
	exit 1
fi

IP=`ifconfig eth2 | grep 'inet addr:' | awk '{ print $2 }' | sed 's/.*://'`
ifconfig eth2 0.0.0.0
brctl addbr br0
brctl addif br0 eth2
ifconfig br0 $IP netmask 255.255.255.0
