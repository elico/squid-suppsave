#!/usr/bin/env bash

function collect-machine-info() {
	lshw
	lshw -short
	lshw -html
	lscpu
	lsblk
	lsblk -a
	lsusb
	lsusb -v
	lspci
	lspci -t
	lspci -v
	lsscsi
	lsscsi -s
	fdisk -l
	dmidecode -t memory
	dmidecode -t system
	dmidecode -t bios
	dmidecode -t processor
	blkid
	ip address show
	ip link show
	ip route	
	ip rule
	lsns
	uname
	uname -n
	uname -v
	uname -r
	uname -m
	uname -a
	free -m
	free -h
	df -m
	df -h
	ss -lptn
	ss -lpt
	ss -lpun
	ss -lpu
	ss -lpn
	ss -n
	lsof -n
	cat /proc/cpuinfo
	cat /proc/meminfo
	cat /proc/partitions
	cat /proc/mounts
	cat /proc/loadavg
	uptime
	dmesg
	tree -d /sys/devices
	cat /etc/passwd
	cat /etc/group
	mount | column -t
	cat /proc/version
	cat /proc/scsi/scsi
	cat /proc/partitions
	nft -nnn list ruleset
	iptables-save
}

set -x

collect-machine-info

set +x
