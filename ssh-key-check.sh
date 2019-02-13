#!/bin/bash

PRI_KEY=/root/.ssh/id_rsa
PUB_KEY=/root/.ssh/id_rsa.pub

# Check if private key file is newer than pub key
if [ "$PUB_KEY" -ot "$PRI_KEY" ]; then
	echo "private file is newer than public file"
	ls -al $PRI_KEY $PUB_KEY

	# generate keys first
	pushd /tmp/env
	./env.py -f -k
	
	popd
fi

pushd /tmp/env/scripts
source ./mount-and-copy-ssh-key.sh
popd
