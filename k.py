#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

# L<x>
target_level = 3
boot_level = target_level

###### DVH config ###################
dvh_vp = True
dvh_idle = ['Y'] * target_level
dvh_idle[0] = 'N'
dvh_ipi = ['Y'] * target_level
dvh_timer = ['Y'] * target_level

dry_run = False
old_options = True
#####################################

PI = ' --pi'
OV = ' -o' #overcommit
PIN = ' -w'
QEMU = ' --qemu qemu-pi'

cmd_cd = 'cd /srv/vm'
cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'
pin_waiting='waiting for connection.*server'

dvh_vp_cmd = []
for l in range(target_level):
    if l == 0:
        dvh_vp_cmd.append(cmd_viommu + PI)
    elif l == target_level - 1:
        dvh_vp_cmd.append(cmd_vfio)
    else:
        dvh_vp_cmd.append(cmd_vfio_viommu + PI)

hostname = os.popen('hostname | cut -d . -f1').read().strip()
hostnames = []
hostnames.append(hostname)
hostnames += ["L1", "L2", "L3"]

def wait_for_prompt(child, hostname):
    child.expect('%s.*#' % hostname)

def pin_vcpus(level):
    l1_addr='10.10.1.100'

    if level == 0:
        os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
    if level == 1:
        os.system('ssh root@%s "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"' % l1_addr)
    if level == 2:
        os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
    print ("vcpu is pinned")


def configure_dvh(dvh, level):

    cmd2_name = ""
    cmd2_on = False

    if dvh == 'virtual_idle':
        enable = dvh_idle[level]
        cmd2_name = ''
    elif dvh == 'virtual_ipi':
        enable = dvh_ipi[level]
        cmd2_name = 'ipi_opt'
    elif dvh == 'virtual_timer':
        enable = dvh_timer[level]
        cmd2_name = 'timer_opt'
    else:
        print ("invalid dvh name: %s", dvh)
        sys.exit(0)

    if enable == 'Y':
        cmd2_enable = '1' 
    else:
        cmd2_enable = '0'

    cmd = 'echo %s > /sys/kernel/debug/dvh/%s' % (enable, dvh)
    if old_options:
        cmd2 = 'echo %s > /sys/kernel/debug/kvm/%s' % (cmd2_enable, cmd2_name)
        cmd = cmd + ';' + cmd2

    child.sendline(cmd)

### Main function start ###

child = pexpect.spawn('zsh')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)

for l in range(target_level):

    for dvh_feature in ['virtual_idle', 'virtual_ipi', 'virtual_timer']:
        configure_dvh(dvh_feature, l)
        if dry_run:
            wait_for_prompt(child, hostnames[0])
        else:
            wait_for_prompt(child, hostnames[l])

    if dvh_vp:
        io_cmd = dvh_vp_cmd[l]
    else:
        io_cmd = cmd_pv

    cmd = cmd_cd + ' && ' + io_cmd + PIN

    if dry_run:
        print(cmd)
        continue

    if boot_level == l:
        break

    child.sendline(cmd)
    child.expect(pin_waiting)
    pin_vcpus(l)
    wait_for_prompt(child, hostnames[l+1])


child.interact()

sys.exit(0)
