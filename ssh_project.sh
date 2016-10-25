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
echo "Getting remote port"
PORT=$(ssh sandbox /usr/local/bin/tun.sh | grep ${PROJECTNUM} | awk '{print $3}'| head -n 1)
if [ -z ${PORT} ] 
	then
		echo "No tunnels for ${PROJECTNUM} project"
		exit 1
fi
echo "ssh to remote host"
ssh -o ProxyCommand="ssh sandbox -A -W %h:%p "  -i ~/.ssh/id_rsa_sandbox root@127.0.0.1 -p ${PORT}

