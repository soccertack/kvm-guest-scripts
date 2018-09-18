#!/bin/bash

source common.sh

CONSOLE=mon:stdio
KERNEL=Image
INCOMING=""
# This is not effective on x86
CMDLINE="earlycon=pl011,0x09000000"
DUMPDTB=""
DTB=""
NESTED=""
SMMU="v8"

#Check if we are on a bare-metal machine
uname -n | grep -q cloudlab
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	FS=/vmdata/linaro-trusty.img
	NESTED=",nested=true"
else
#L1 specific settings
	FS=l2.img
fi

HOST_CPU=`nproc`
SMP=`expr $HOST_CPU - 2`

# 12 (default) + 12G per each virt level
# e.g. L2 got 12G, and L1 got 24G and L0 got 36G
# memsize = 12 + (smp - 4) / 2 * 12
MEMSIZE=`expr $SMP \* 6 - 12`

if [[ "$ARCH" == "x86_64" ]]; then
	QEMU=./qemu/x86_64-softmmu/qemu-system-x86_64
	FS=/vm/guest0.img
	MACHINE="q35,accel=kvm"
else
	QEMU="./qemu-system-aarch64"
	# FS is already set
	MACHINE="virt${DUMPDTB}"
fi

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options]\n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
	U="$U    -m | --mem <GB>:       Memory size (default ${MEMSIZE})\n"
	U="$U    -s | --migration-src:   Run the guest as the migration source\n"
	U="$U    -t | --migration-dst: run the guest as the migration dest\n"
	U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
	U="$U    -v | --smmu <version>:  Specify SMMUv3 patch version\n"
	U="$U    -q | --mq <nr>:        Number of multiqueus for virtio-net\n"
	U="$U    -x | --xen:		Run Xen as a guest hypervisor\n"
	U="$U    --pi:		       Enable posted interrupt cap in vIOMMU\n"
	U="$U    --win:		       Run windows guest\n"
	U="$U    --cap:		       Add state capture capability to virtio dev\n"
	U="$U    --dumpdtb <file>       Dump the generated DTB to <file>\n"
	U="$U    --dtb <file>           Use the supplied DTB instead of the auto-generated one\n"
	U="$U    -h | --help:           Show this output\n"
	U="${U}\n"
	echo -e "$U" >&2
}

while :
do
	case "$1" in
	  -c | --cpu)
		SMP="$2"
		shift 2
		;;
	  -m | --mem)
		MEMSIZE="$2"
		shift 2
		;;
	  -s | --migration-src)
		M_SRC=1
		shift 1
		;;
	  -t | --migration-dst)
		M_PORT=5555
		shift 1
		;;
	  -k | --kernel)
		KERNEL="$2"
		shift 2
		;;
	  -s | --serial)
		CONSOLE="file:$2"
		shift 2
		;;
	  -i | --image)
		FS="$2"
		shift 2
		;;
	  -a | --append)
		CMDLINE="$2"
		shift 2
		;;
	  -v | --smmu)
		SMMU="$2"
		shift 2
		;;
	  -q | --mq)
		MQ_NUM="$2"
		shift 2
		;;
	  --pi)
		PI=1
		shift 1
		;;
	  --dumpdtb)
		DUMPDTB=",dumpdtb=$2"
		shift 2
		;;
	  --dtb)
		DTB="-dtb $2"
		shift 2
		;;
	  --win)
	  	WINDOWS=1
		shift 1
		;;
	  -x | --xen)
		XEN=1
		shift 1
		;;
	  --cap)
		VIRTIO_STATE_CAP=1
		shift 1
		;;
	  -h | --help)
		usage ""
		exit 1
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		break
		;;
	esac
done

USER_NETDEV="-netdev user,id=net0,hostfwd=tcp::2222-:22"
USER_NETDEV="$USER_NETDEV -device virtio-net-pci,netdev=net0"

echo "Using bridged networking"
VIRTIO_NETDEV="-netdev tap,id=net1,vhost=on"
if [ ! -z "$MQ_NUM" ]; then
	VIRTIO_NETDEV="$VIRTIO_NETDEV,queues=$MQ_NUM"
else
	VIRTIO_NETDEV="$VIRTIO_NETDEV,helper=/srv/vm/qemu/qemu-bridge-helper"
fi

VIRTIO_NETDEV="$VIRTIO_NETDEV -device virtio-net-pci,netdev=net1"
if [ ! -z "$MQ_NUM" ]; then
	VECTOR_NUM=`expr 2 \* "$MQ_NUM" + 2`
	VIRTIO_NETDEV="$VIRTIO_NETDEV,mq=on,vectors=$VECTOR_NUM"
fi

# Save mac addresses in this subnet
MAC_TMP="/tmp/mac"
echo "Running nmap"
nmap -n -sP 10.10.1.0/24 > $MAC_TMP
err=$?
if [ $err != 0 ]; then
	echo "nmap returned an error. Did you install nmap?"
	exit
fi

echo "nmap Done"

# Run nmap before calling this function
find_available_mac() {
	MAC_PREFIX=$1
	USED=$2

	for i in {0..15}; do
		hex=$(printf '%x' $i) 

		if [ $hex == "$USED" ]; then
			continue
		fi

		grep -q -i $MAC_PREFIX$hex $MAC_TMP
		err=$?

		if [[ $err != 0 ]]; then
			#nmap doesn't show this machine's MAC addrs
			ifconfig | grep -q -i $MAC_PREFIX$hex
			err=$?

			if [[ $err != 0 ]]; then
				MAC_POSTFIX=$hex
				return	
			fi
		fi
	done

	MAC_POSTFIX="X"
}

MAC_PREFIX="de:ad:be:ef:f6:c"
find_available_mac $MAC_PREFIX
if [ $MAC_POSTFIX == "X" ]; then
	echo "No available MAC addr with "$MAC_PREFIX
	exit
fi
VIRTIO_NETDEV="$VIRTIO_NETDEV,mac=$MAC_PREFIX$MAC_POSTFIX"
NETDEV1_POSTFIX=$MAC_POSTFIX

MAC_PREFIX="de:ad:be:ef:41:5"
find_available_mac $MAC_PREFIX
if [ $MAC_POSTFIX == "X" ]; then
	echo "No available MAC addr with "$MAC_PREFIX
	exit
fi
USER_NETDEV="$USER_NETDEV,mac=$MAC_PREFIX$MAC_POSTFIX"

set_remote_fs () {
	mount | grep sdc 2>&1 > /dev/null
	if [[ $? != 0 ]]; then
		mount 10.10.1.1:/sdc /sdc
	fi
	FS=/sdc/$1
}

# Migration related settings
TELNET_PORT=4444
if [ -n "$M_SRC" ] || [ -n "$M_PORT" ]; then
	if [ -n "$M_PORT" ]; then
		TELNET_PORT=4445
		MIGRAION="-incoming tcp:0:$M_PORT"

		# Tweak params which conflict with the source
		USER_NETDEV=`echo $USER_NETDEV | sed  "s/2222/2223/"`
		USER_NETDEV=`echo $USER_NETDEV | sed  "s/ef:41/ef:42/"`
	fi

	CONSOLE="telnet:127.0.0.1:$TELNET_PORT,server,nowait"
	MON="-monitor stdio"
	set_remote_fs guest0.img

	# We only need migration patch for L1+L2 VM migration
	if [ "$IS_HOST" == 1 ]; then
		QEMU=./qemu-migration/x86_64-softmmu/qemu-system-x86_64
	fi

	if [ "$WINDOWS" == 1 ]; then
		echo "We don't support Windows migration yet"
		# TODO: just set FS correctly.
		exit
	fi
fi

if [ "$WINDOWS" == 1 ]; then
	set_remote_fs  win.img
	WIN_ISO=en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso
	VIRTIO_ISO=virtio-win.iso
	CPU_HV=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
	WINDOWS_OPTIONS=""
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -usb -device usb-tablet"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -rtc base=localtime,clock=host"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -vnc 127.0.0.1:2"
	#WINDOWS_OPTIONS="$WINDOWS_OPTIONS --cdrom ${WIN_ISO}"
	#WINDOWS_OPTIONS="$WINDOWS_OPTIONS --drive file=${VIRTIO_ISO},index=3,media=cdrom"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS --cdrom ${VIRTIO_ISO}"
	CONSOLE="telnet:127.0.0.1:$TELNET_PORT,server,nowait"
	MON="-monitor stdio"
fi

if [ "$XEN" == 1 ]; then
	# If we do viommu + vfio, which changes QEMU, the QEMU has already patch for Xen.
	# So, this QEMU is only for the viommu only case.
	QEMU="./qemu-xen-fix/x86_64-softmmu/qemu-system-x86_64"

	# If we alloc 24G for L1, and dedicate 12G for L2 dom0, then we can't alloc 12G for L2 domU.
	# So, give 1G buffer. Note that L2 dom0 and L2 domU will remain to have exactly 12G.
	MEMSIZE=`expr $MEMSIZE + 1`
fi

if [ "$IS_HOST" == 1 ]; then
	# Install host ssh key to VM
	source ssh-key-check.sh
fi

