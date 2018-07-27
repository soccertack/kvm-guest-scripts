#!/usr/bin/python
import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import re

LOCAL_SOCKET = 8890

def wait_for_L0_shell(child):
	child.expect('kvm-node.*')

def wait_for_L1_shell(child):
	child.expect('\[L1.*\]')

def wait_for_L2_shell(child):
	child.expect('\[L2.*\]')

def wait_for_qemu_shell(child):
	child.expect('\(qemu\)')

def get_level():
	level  = int(raw_input("Enter virtualization level [2]: ") or "2")
	if level < 1:
		print ("We don't (need to) support L0")
		sys.exit(0)
	if level > 3:
		print ("Are you sure to run virt level %d?" % level)
		sleep(5)

	return level

# iovirt: pv, pt(pass-through), or vp(virtual-passthough)
def get_iovirt():
	iovirt = raw_input("Enter I/O virtualization level [pv]: ") or "pv"
	if iovirt not in ["pv", "pt", "vp"]:
		print ("Enter pv, pt, or vp")
		sys.exit(0)
	return iovirt


def boot_vm(iovirt, child):

	mylevel = 0
	if iovirt == "vp":
		child.sendline('cd /srv/vm && ./run-guest-viommu.sh -s')
	elif iovirt == "pv":
		child.sendline('cd /srv/vm && ./run-guest.sh -s')
	elif iovirt == "pt":
		if level == 1:
			child.sendline('cd /srv/vm && ./run-guest-vfio.sh -s')
		else:
			child.sendline('cd /srv/vm && ./run-guest-vfio-viommu.sh -s')

	return

def boot_nvm(iovirt, child):
	if iovirt == "vp" or iovirt == "pt":
		child.sendline('cd ~/vm && ./run-guest-vfio.sh')
	else:
		child.sendline('cd ~/vm && ./run-guest.sh')

def start_qemu(iovirt):
	qemu_child = pexpect.spawn('bash')
	fout = file('mylog.txt','w')
	qemu_child.logfile = fout
	qemu_child.timeout=None

	qemu_child.sendline('')
	wait_for_L0_shell(qemu_child)
	boot_vm(iovirt, qemu_child)

	return qemu_child

def start_telnet():
	telnet_child = pexpect.spawn('bash')
	telnet_child.logfile = sys.stdout
	telnet_child.timeout=None

	telnet_child.sendline('')
	wait_for_L0_shell(telnet_child)
	telnet_child.sendline('telnet localhost 4444')

	return telnet_child

def do_some_job(telnet_child, qemu_child):
	# TODO: run migration command and wait for it completed.
	sec = 5
	print ("Wait for %d seconds" % sec)
	time.sleep(sec)
	telnet_child.sendline('ls')
	wait_for_L2_shell(telnet_child)

	qemu_child.sendline('help')
	wait_for_qemu_shell(qemu_child)

def shutdown_vm(child):
	child.sendline('h')
	wait_for_L1_shell(child)
	child.sendline('h')
	wait_for_L0_shell(child)

def start_server():
	serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

	print ("Try to bind...")
	try:
		serversocket.bind(('', 8889))
	except socket.error:
		return
	print ("Done.")

	print ("Try to listen...")
	serversocket.listen(1) # become a server socket.
	print ("Done.")

	print ("Try to accept...")
	connection, address = serversocket.accept()
	print ("Done.")

	return connection

def wait_for_clients(connection, msg):

	print ("Waiting for clients.")
	while True:
	    buf = connection.recv(64)
	    if len(buf) > 0:
		print buf
		if buf == msg:
			break	

level = get_level()
iovirt = get_iovirt()

# Start the server
connection = start_server()
if connection is None:
	sys.exit(0)

# Wait for other clients ready
wait_for_clients(connection, "Dest ready")

# Start the destination QEMU
connection.send("Dest run")
wait_for_clients(connection, "Dest running")

# Start QEMU
qemu_child = start_qemu(iovirt)
wait_for_qemu_shell(qemu_child)

# Start telnet
telnet_child = start_telnet()

# Make sure we have L1 console
telnet_child.sendline('')
wait_for_L1_shell(telnet_child)

# Start nested VM in telnet
boot_nvm(iovirt, telnet_child)
wait_for_L2_shell(telnet_child)
# Nested VM boot completed at this point

# Do some job
do_some_job(telnet_child, qemu_child)

# Shutdown the virtual machine (L2 and L1)
shutdown_vm(telnet_child)

