#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

l1_addr='10.10.1.100'

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

cmd_cd = 'cd /srv/vm'
cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'

def configure_dvh(dvh, enable):
    cmd = 'echo %s > /sys/kernel/debug/dvh/%s' % (enable, dvh)
    child.sendline(cmd)

pin_waiting='waiting for connection.*server'

###### DVH config
L0_vidle='N'
L0_vipi='N'
L0_vtimer='N'

L1_vidle='N'
L1_vipi='N'
L1_vtimer='N'

L2_vidle='N'
L2_vipi='N'
L2_vtimer='N'
#####
hostname = os.popen('hostname | cut -d . -f1').read().strip()

child = pexpect.spawn('bash')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)

configure_dvh('virtual_idle', L0_vidle)
wait_for_prompt(child, hostname)
configure_dvh('virtual_ipi', L0_vipi)
wait_for_prompt(child, hostname)
configure_dvh('virtual_timer', L0_vtimer)
wait_for_prompt(child, hostname)

PI = ' --pi'
OV = ' -o' #overcommit
PIN = ' -w'
QEMU = ' --qemu qemu-pi'

pv = False

if pv:
    child.sendline(cmd_cd + ' && ' + cmd_pv + PIN)
else:
    child.sendline(cmd_cd + ' && ' + cmd_viommu + PIN + QEMU)

child.expect(pin_waiting)
pin_vcpus(0)
child.expect('L1.*$')

configure_dvh('virtual_idle', L1_vidle)
child.expect('L1.*$')
configure_dvh('virtual_ipi', L1_vipi)
child.expect('L1.*$')
configure_dvh('virtual_timer', L1_vtimer)
child.expect('L1.*$')

#child.sendline('echo 0 >/sys/kernel/debug/kvm/timer_opt')
#child.expect('L1.*$')

if pv:
    child.sendline(cmd_cd + ' && ' + cmd_pv + PIN)
else:
    child.sendline(cmd_cd + ' && ' + cmd_vfio_viommu + PIN + QEMU)
child.expect(pin_waiting)
pin_vcpus(1)
child.expect('L2.*$')

configure_dvh('virtual_idle', L2_vidle)
child.expect('L2.*$')
configure_dvh('virtual_ipi', L2_vipi)
child.expect('L2.*$')
configure_dvh('virtual_timer', L2_vtimer)
child.expect('L2.*$')

if pv:
    child.sendline(cmd_cd + ' && ' + cmd_pv + PIN)
else:
    child.sendline(cmd_cd + ' && ' + cmd_vfio + PIN)
child.expect(pin_waiting)
pin_vcpus(2)

child.interact()
sys.exit(0)
