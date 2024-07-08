#!/bin/sh

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}

while getopts "r:c:v:" opt
do
    case $opt in
        (c) CLUSTERNAME=$OPTARG
            ;;
        (r) REGION=$OPTARG
            ;;
	(v) VERSION=$OPTARG
	    ;;
        (*) printf "Illegal option '-%s'\n" "$opt" && exit 1
            ;;
    esac
done

if [ -z $CLUSTERNAME ]; then
	echo "Need a cluster name"
	exit
fi

if [ -z $REGION ]; then
	echo "Need a AWS region"
	exit
fi

if [ -z $VERSION ]; then
	echo "Need a OCP version"
	exit
fi

log -n "Creating the metadata.json ..."
mkdir -p /tmp/${CLUSTERNAME}
echo "{\"clusterName\":\"${CLUSTERNAME}\",\"clusterID\":\"\",\"infraID\":\"${CLUSTERNAME}\",\"aws\":{\"region\":\"${REGION}\",\"identifier\":[{\"kubernetes.io/cluster/${CLUSTERNAME}\":\"owned\"}]}}" > /tmp/${CLUSTERNAME}/metadata.json

log "Creating the metadata.json ... done"
log -n "Trying to destroy cluster using the metadata.json generated ..."
if [ -d /usr/local/bin/ocp$VERSION ]; then
   OCPVERSION=$(/usr/local/bin/ocp$VERSION/openshift-install version | grep openshift-install)
   echo "Using /usr/local/bin/ocp$VERSION/openshift-install to destroy the cluster [$VERSION]"
   #/usr/local/bin/ocp$VERSION/openshift-install destroy cluster --dir /tmp/${CLUSTERNAME}
else
   OCPVERSION=$(/usr/local/bin/openshift-install version | grep openshift-install)
   echo "Using /usr/local/bin/openshift-install to create the cluster [$OCPVERSION]"
   #/usr/local/bin/openshift-install destroy cluster --dir /tmp/${CLUSTERNAME}
fi
