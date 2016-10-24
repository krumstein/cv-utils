#!/bin/bash

display_usage() { 
	echo "This script mount remote directory to ~/Work/CV/projects/PROJECT_ID/mnt/ and forward remote 80 and 443 ports to local 8080 and 8443" 
	echo -e "\nUsage:\n$0 project_number \n" 
	return 0
} 

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

if [  $# -lt 1 ] 
	then 
		display_usage
		exit 1
fi 
PROJECTNUM=$1
MNTPOINT=~/Work/CV/projects/${PROJECTNUM}/mnt
echo "Creating directory for mount point"
mkdir -p ${MNTPOINT}
echo "Getting remote port"
PORT=$(ssh sandbox /usr/local/bin/tun.sh | grep ${PROJECTNUM} | awk '{print $3}'| head -n 1)
if [ -z ${PORT} ] 
	then
		echo "No tunnels for ${PROJECTNUM} project"
		exit 1
fi
echo "Checking if already mounted"
mount | grep ${MNTPOINT}
if [ $? -eq 1 ]
then
	echo "Mounting"
	sshfs -o ssh_command=~/Work/CV/cv-utils/jump_server  root@127.0.0.1:/ -p ${PORT} ${MNTPOINT}
	if [ $? -eq 0 ]
		then
			echo "mount success! You should be able to access files in ~/Work/CV/projects/${PROJECTNUM}/mnt/"
		else
			echo "mount failed :("
	fi
else
	echo "already mounted"
fi

echo "trying to find a local port:"
PORT_START=8000
OPENPORTS=$(netstat -lntp 2>/dev/null| awk '{print $4}' | grep ":" | sed 's/^.*://' | sort -u | tr  '\n' ' ')
while containsElement ${PORT_START} ${OPENPORTS}
do
	PORT_START=$((PORT_START+1))
done
echo "port found! ${PORT_START}"
echo "forwarding port 80"
ssh -N -f -A -o ProxyCommand="ssh sandbox -A -W %h:%p " -L ${PORT_START}:127.0.0.1:80 -i ~/.ssh/id_rsa_sandbox root@127.0.0.1 -p ${PORT}
echo "go to http://127.0.0.1:${PORT_START}"

OPENPORTS=$(netstat -lntp 2>/dev/null| awk '{print $4}' | grep ":" | sed 's/^.*://' | sort -u | tr  '\n' ' ')
while containsElement ${PORT_START} ${OPENPORTS}
do
	PORT_START=$((PORT_START+1))
done
echo "port found! ${PORT_START}"
echo "forwarding port 443"
ssh -N -f -A -o ProxyCommand="ssh sandbox -A -W %h:%p " -L ${PORT_START}:127.0.0.1:443 -i ~/.ssh/id_rsa_sandbox root@127.0.0.1 -p ${PORT}
echo "go to https://127.0.0.1:${PORT_START}"

