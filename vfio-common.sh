ARCH=`uname -m`
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

