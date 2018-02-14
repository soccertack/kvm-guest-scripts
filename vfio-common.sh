source common.sh
ARCH=`uname -m`
SRIOV="/sys/class/net/$ETH/device/sriov_numvfs"
BDF=""
BDF2=""

function create_vf()
{
	VF=`cat $SRIOV`
	if [[ $VF == 0 ]]; then
		echo 2 > $SRIOV
	fi
}

CLOUD=""
uname -a | grep -q apt
err=$?
if [[ $err == 0 ]]; then
	CLOUD="APT"
fi

ifconfig | grep -q "128\."
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	if [[ "$ARCH" == "x86_64" ]]; then
		create_vf
		if [[ "$CLOUD" == "APT" ]]; then
			echo "x86 APT"
			DEV_ID="15b3 1003"
			BDF="0000:08:00.0"
		else
			DEV_ID="8086 10ed"
			# This is VF BDF
			BDF="0000:06:10.0"
			BDF2="0000:06:10.2"
		fi
		TYPE1_OPTION=""
		echo "x86 bare-metal passthrough!!"
	else
		echo "Passthrough on ARM bare-meatl is not available, yet."
		exit
	fi
else
	#L1 specific settings
	DEV_ID="1af4 1041"

	if [[ "$ARCH" == "x86_64" ]]; then
		BDF="0000:01:00.0"
		BDF_S="0000\:01\:00.0"
		TYPE1_OPTION=""
	else
		BDF="0000:00:04.0"
		BDF_S="0000\:00\:04.0"
		TYPE1_OPTION="allow_unsafe_interrupts=1"
	fi
fi

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"
if [[ $BDF2 != "" ]]; then
	VFIO_DEV2="-device vfio-pci,host=$BDF2,id=net3"
fi

# Do not provide a normal virtio-net device.
# Doing that will result in a severe performance drop.
VIRTIO_NETDEV=""
