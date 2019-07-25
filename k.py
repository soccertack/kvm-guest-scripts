#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

cmd_cd = 'cd /srv/vm'
cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'

# L<x>
target_level = 2

###### DVH config
pv = False
dvh_idle = ['Y'] * target_level
dvh_idle[0] = 'N'
dvh_ipi = ['Y'] * target_level
dvh_timer = ['Y'] * target_level

PI = ' --pi'
OV = ' -o' #overcommit
PIN = ' -w'
QEMU = ' --qemu qemu-pi'
dvh_vp = []
for l in range(target_level):
    if l == 0:
        dvh_vp.append(cmd_viommu + QEMU)
    elif l == target_level - 1:
        dvh_vp.append(cmd_vfio)
    else:
        dvh_vp.append(cmd_vfio_viommu + QEMU)

#####

l1_addr='10.10.1.100'

hostname = os.popen('hostname | cut -d . -f1').read().strip()
hostnames = []
hostnames.append(hostname)
hostnames += ["L1", "L2", "L3"]

def wait_for_prompt(child, hostname):
    child.expect('%s.*#' % hostname)

def pin_vcpus(level):
        if level == 0:
	        os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	if level == 1:
		os.system('ssh root@%s "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"' % l1_addr)
	if level == 2:
		os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")


def configure_dvh(dvh, enable):
    cmd = 'echo %s > /sys/kernel/debug/dvh/%s' % (enable, dvh)
    child.sendline(cmd)

pin_waiting='waiting for connection.*server'


child = pexpect.spawn('bash')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)

for l in range(target_level):

    configure_dvh('virtual_idle', dvh_idle[l])
    wait_for_prompt(child, hostnames[l])
    configure_dvh('virtual_ipi', dvh_ipi[l])
    wait_for_prompt(child, hostnames[l])
    configure_dvh('virtual_timer', dvh_timer[l])
    wait_for_prompt(child, hostnames[l])

    if pv:
        child.sendline(cmd_cd + ' && ' + cmd_pv + PIN)
    else:
        child.sendline(cmd_cd + ' && ' + dvh_vp[l] + PIN)

    child.expect(pin_waiting)
    pin_vcpus(l)
    wait_for_prompt(child, hostnames[l+1])


child.interact()

sys.exit(0)
