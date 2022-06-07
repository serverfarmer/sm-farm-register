#!/bin/bash
. /opt/farm/ext/net-utils/functions

if [ "$1" = "" ]; then
	echo "usage: $0 <hostname[:port]>"
	exit 1
elif [ "`resolve_host $1`" = "" ]; then
	echo "error: parameter $1 not conforming hostname format, or given hostname is invalid"
	exit 1
fi

server=$1
if [ -z "${server##*:*}" ]; then
	host="${server%:*}"
	port="${server##*:}"
else
	host=$server
	port=22
fi

if grep -q "^$host:" ~/.serverfarmer/inventory/*.hosts || grep -q "^$host$" ~/.serverfarmer/inventory/*.hosts; then
	echo "error: host $host already added"
	exit 1
fi

sshkey=`/opt/farm/ext/keys/get-ssh-management-key.sh $host`
ssh -i $sshkey -p $port -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@$host uptime >/dev/null 2>/dev/null

if [[ $? != 0 ]]; then
	echo "error: host $server denied access"
	exit 1
fi

hwtype=`ssh -i $sshkey -p $port root@$host /opt/farm/ext/system/detect-hardware-type.sh`
docker=`ssh -i $sshkey -p $port root@$host "which docker 2>/dev/null"`
openvz=`ssh -i $sshkey -p $port root@$host "cat /proc/vz/version 2>/dev/null"`
netmgr=`ssh -i $sshkey -p $port root@$host "cat /etc/X11/xinit/xinitrc 2>/dev/null"`
cloud=`ssh -i $sshkey -p $port root@$host "cat /etc/cloud/build.info 2>/dev/null"`

if [ "$netmgr" != "" ]; then
	echo $server >>~/.serverfarmer/inventory/workstation.hosts
elif [ $hwtype = "physical" ]; then
	echo $server >>~/.serverfarmer/inventory/physical.hosts
elif [ $hwtype = "lxc" ]; then
	echo $server >>~/.serverfarmer/inventory/lxc.hosts
elif [ "$openvz" != "" ]; then
	echo $server >>~/.serverfarmer/inventory/container.hosts
elif [ "$cloud" != "" ]; then
	echo $server >>~/.serverfarmer/inventory/cloud.hosts
elif [ $hwtype = "guest" ]; then
	echo $server >>~/.serverfarmer/inventory/virtual.hosts
fi

if [ "$docker" != "" ]; then
	echo $server >>~/.serverfarmer/inventory/docker.hosts
fi

/opt/farm/mgr/farm-register/add-dedicated-key.sh $server root

if [ $hwtype != "lxc" ]; then
	/opt/farm/mgr/farm-register/add-dedicated-key.sh $server backup

	if [ -x /opt/farm/mgr/backup-collector/add-backup-host.sh ]; then
		/opt/farm/mgr/backup-collector/add-backup-host.sh $server
	fi
fi
