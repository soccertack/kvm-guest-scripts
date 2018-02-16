ETH=`ifconfig | grep "10\.10\." -B1 | head -n 1 | awk '{ print $1 }'`

