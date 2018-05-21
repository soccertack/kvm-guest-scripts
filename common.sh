ETH=`ifconfig | grep "10\.10\." -B1 | head -n 1 | awk '{ print $1 }'`

if [[ "$ETH" == "br0" ]]; then
	ETH=`brctl show | grep br0 | awk '{ print $4 }'`
fi

ARCH=`uname -m`
