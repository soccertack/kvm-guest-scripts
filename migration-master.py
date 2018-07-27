#!/usr/bin/python
import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import re

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

	child.expect('\[L2.*\]')

def start_qemu(iovirt):

	qemu_child = pexpect.spawn('bash')
	fout = file('mylog.txt','w')
	qemu_child.logfile = fout
	qemu_child.timeout=None

	qemu_child.sendline('')
	qemu_child.expect('kvm-node.*')
	boot_vm(iovirt, qemu_child)

	return qemu_child

level = get_level()
iovirt = get_iovirt()

# Start QEMU
qemu_child = start_qemu(iovirt)
qemu_child.expect('\(qemu\)')

telnet_child = pexpect.spawn('bash')
telnet_child.logfile = sys.stdout
telnet_child.timeout=None

telnet_child.sendline('')
telnet_child.expect('kvm-node.*')
telnet_child.sendline('telnet localhost 4444')

telnet_child.sendline('')
telnet_child.expect('L1.*$')
boot_nvm(iovirt, telnet_child)
print ("==========================")
print ("==========================")
print ("==========================")
print ("==========================")
print ("==========================")
print ("==========================")
time.sleep(5)
telnet_child.sendline('ls')
telnet_child.expect('L2.*$')

ree = re.compile('\(qemu\)')
qemu_child.sendline('help')
qemu_child.expect('\(qemu\)')
#qemu_child.expect(ree)
qemu_child.sendline('abde')
qemu_child.expect('\(qemu\)')
#qemu_child.expect(ree)
qemu_child.sendline('help')
qemu_child.expect('\(qemu\)')
#qemu_child.expect(ree)

telnet_child.sendline('h')
telnet_child.expect('L1.*$')
telnet_child.sendline('h')
telnet_child.expect('L1.*$')
telnet_child.expect('kvm-node.*')
