#!/bin/bash

ETH=`ifconfig | grep "10\.10\." -B1 | head -n 1 | awk '{ print $1 }'`

echo $ETH

ifconfig $ETH > /dev/null 2>&1
err=$?
if [[ $err != 0 ]]; then
	echo "$ETH not found - are you using the right topology?" >&2
	exit 1
fi

IP=`ifconfig $ETH | grep 'inet addr:' | awk '{ print $2 }' | sed 's/.*://'`
echo $IP
ifconfig $ETH 0.0.0.0
brctl addbr br0
brctl addif br0 $ETH
ifconfig br0 $IP netmask 255.255.255.0
