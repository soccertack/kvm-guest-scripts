source common.sh
ARCH=`uname -m`
SRIOV="/sys/class/net/$ETH/device/sriov_numvfs"

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

# Create VFs in x86 L0
if [[ $err == 0 ]]; then
	if [[ "$ARCH" == "x86_64" ]]; then
		create_vf
	fi
fi

# TODO: test this on ARM and remove this comment!
# This physical network device is for Wisc machines.
BDF_P=`lspci | grep 82599.*Virtual.Function | head -1 | awk '{ print $1 }'`
BDF_V=`lspci | grep Red.Hat.*1041 | awk '{ print $1 }'`

if [[ "$BDF_P" != "" && "$BDF_V" != "" ]]; then
	echo "We have VF and virtio-net. Not sure what we want to do"
	exit
elif [[ "$BDF_P" == "" && "$BDF_V" == "" ]]; then
	echo "We have no device to assign to a VM."
	exit
elif [[ "$BDF_P" != "" ]]; then
	BDF=$BDF_P
else
	BDF=$BDF_V
fi

DEV_ID=`lspci -nn | grep $BDF | cut -d[ -f3 | cut -d] -f1 | sed 's/:/ /'`

if [[ "$ARCH" == "aarch64" ]]; then
	# ARM IOMMU emulation doesn't support interrupt remapping yet
	# Enable this option on x86 if you want not to use irq-remapping
	TYPE1_OPTION="allow_unsafe_interrupts=1"
fi

echo "BDF: "$BDF
echo "DEV_ID: "$DEV_ID

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"
