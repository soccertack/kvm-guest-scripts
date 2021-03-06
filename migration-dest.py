#!/usr/bin/python
import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import re

def wait_for_L0_shell(child):
	child.expect('kvm-dest.*')

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

	option = "-t 5555"

	if iovirt == "vp":
		child.sendline('cd /srv/vm && ./run-guest-viommu.sh %s' % option)
	elif iovirt == "pv":
		child.sendline('cd /srv/vm && ./run-guest.sh %s' % option)
	elif iovirt == "pt":
		child.sendline('cd /srv/vm && ./run-guest-vfio.sh %s' % option)

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
	telnet_child.sendline('telnet localhost 4445')

	return telnet_child

def do_some_job(telnet_child, qemu_child):
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

def connect_to_server():
	print("Trying to connect to the server")
	clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	clientsocket.connect(('10.10.1.2', 8889))
	print("Connected")
	return clientsocket


def wait_for_any_msg(s):
	while True:
		buf = s.recv(64)
		if len(buf) > 0:
			print buf
			return buf

def wait_for_msg(s, msg):
	while True:
		buf = s.recv(64)
		if len(buf) > 0:
			print buf
			if buf == msg:
				break


# TODO get this from the server
# level = get_level()
#iovirt = get_iovirt()

clientsocket = connect_to_server()
clientsocket.send('Dest ready')

level = wait_for_any_msg(clientsocket)
clientsocket.send('Level received')
level = int(level)

iovirt = wait_for_any_msg(clientsocket)
clientsocket.send('iovirt received')

iteration = wait_for_any_msg(clientsocket)
clientsocket.send('iteration received')
iteration = int(iteration)

for i in range(iteration):
	wait_for_msg(clientsocket, "Dest run")

	# Start QEMU
	qemu_child = start_qemu(iovirt)
	wait_for_qemu_shell(qemu_child)

	clientsocket.send('Dest running')

	wait_for_msg(clientsocket, "Migration done")

	# Shutdown the virtual machine (L2 and L1)
	# Start telnet
	telnet_child = start_telnet()
	print ("Started console")

	# Make sure we have L2 console
	telnet_child.sendline('')
	wait_for_L2_shell(telnet_child)
	print ("console working")

	shutdown_vm(telnet_child)
	print ("VM halted")
	clientsocket.send('Dest shutdown')
