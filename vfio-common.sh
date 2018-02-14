ARCH=`uname -m`

ifconfig | grep -q "128\."
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	if [[ "$ARCH" == "x86_64" ]]; then
		DEV_ID="8086 10fb"
		BDF="0000:06:00.0"
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
