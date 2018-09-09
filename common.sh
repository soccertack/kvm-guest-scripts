ETH=`ifconfig | grep "10\.10\." -B1 | head -n 1 | awk '{ print $1 }'`
IP=`ifconfig | grep "10\.10\." | awk '{ print $2 }' | cut -d ":" -f2`

case $ETH in
 *br*)
    ETH=`brctl show | grep $ETH | awk '{ print $4 }'`
 ;;
esac

ARCH=`uname -m`
