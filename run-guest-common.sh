#!/bin/bash

CONSOLE=mon:stdio
SMP=1
MEMSIZE=$((1 * 1024))
KERNEL=Image
INCOMING=""
FS=/vmdata/linaro-trusty.img
CMDLINE=""
DUMPDTB=""
DTB=""
L0=0
NESTED=""
QEMU="./qemu-system-aarch64"

ifconfig | grep -q "10.10.1.2 "
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	L0=1
	SMP=6
	MEMSIZE=$((16 * 1024))
	FS=/vmdata/linaro-trusty.img
	NESTED=",nested=true"
else
#L1 specific settings
	SMP=4
	MEMSIZE=$((12 * 1024))
	FS=l2.img
fi

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options]\n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
	U="$U    -m | --mem <MB>:       Memory size (default ${MEMSIZE})\n"
	U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
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
	  --dumpdtb)
		DUMPDTB=",dumpdtb=$2"
		shift 2
		;;
	  --dtb)
		DTB="-dtb $2"
		shift 2
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
VIRTIO_NETDEV="-netdev tap,id=net1,helper=/srv/vm/qemu/qemu-bridge-helper,vhost=on"
VIRTIO_NETDEV="$VIRTIO_NETDEV -device virtio-net-pci,netdev=net1"

if [[ $L0 == 1 ]]; then
	VIRTIO_NETDEV="$VIRTIO_NETDEV,mac=de:ad:be:ef:f6:cd"
	USER_NETDEV="$USER_NETDEV,mac=de:ad:be:ef:41:50"
else
	VIRTIO_NETDEV="$VIRTIO_NETDEV,mac=de:ad:be:ef:f6:ce"
	USER_NETDEV="$USER_NETDEV,mac=de:ad:be:ef:41:51"
fi
