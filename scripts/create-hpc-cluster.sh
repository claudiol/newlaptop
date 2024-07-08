#!/bin/bash
#
#set -ex -o pipefail

CLUSTERDIR=/home/claudiol/work/clusters
NODECOUNT=1
NODETYPE=m5.xlarge

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

function usage {
	log "$0 -c <clustername> -n <node count> -r <region> -v 4.12"
	exit
}

while getopts "t:c:n:r:v:l" opt
do
    case $opt in
	(n) NODECOUNT=$OPTARG
	    ;;
	(r) REGION=$OPTARG
	    ;;
	(c) CLUSTERNAME=$OPTARG
	    ;;
	(l) LIST=true
	    ;;
	(t) NODETYPE=$OPTARG
	    ;;
	(v) VERSION=$OPTARG
	    ;;
	(h) usage
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" && exit 1
	    ;;
    esac
done

OCPVERSIONS=$(curl -X GET https://quay.io/api/v1/repository/openshift-release-dev/ocp-release?tab=tags | jq '.tags[].name')

if [ "$LIST" == "true" ]; then
  echo "Avalable versions are: $OCPVERSIONS"
  exit
fi

if [ "$CLUSTERNAME." == "." ]; then
  echo "Need a cluster name"
  usage
fi

if [ "$VERSION." == "." ]; then
  echo "Need a release image version"
  usage
elif [[ "$VERSION" != *"x86"* ]]; then
  log "Pass in one of these versions:"
  log "$OCPVERSIONS"
  exit
fi

if [ "$REGION." == "." ]; then
  REGION=us-west-2
fi

if [[ $NODECOUNT =~ ^[0-9]+$ ]]; then
  log "Number of nodes requested: $NODECOUNT" 
else
   echo "${NODECOUNT} is not a number"
   usage
fi

unset KUBECONFIG


set +e
oc whoami
RC=$?
#set -e
echo "RC = $RC "
if [ $RC -ne 0 ]; then
  log "Make sure you are logged in to the hypershift console"
  log "Visit: https://console-openshift-console.apps.hcp.aws.validatedpatterns.io/"
  exit
else   
  USER=$(oc whoami)
  log "Logged in as $USER"
fi


RC=$(hypershift create cluster aws --name $CLUSTERNAME --release-image quay.io/openshift-release-dev/ocp-release:$VERSION --node-pool-replicas=$NODECOUNT --instance-type=$NODETYPE --base-domain aws.validatedpatterns.io --pull-secret ~/.pullsecret.json --aws-creds ~/.aws/credentials --region $REGION; echo $?)

if [ $RC != 0 ]; then
  log "Create cluster failed"
  exit
else
  if [ ! -d $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT ]; then
    mkdir -p $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT 
    echo $REGION > $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-region
  else
    log "$CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT exists! Please remove"
    exit
  fi
fi

log "Waiting for cluster to be created."
~/bin/get-hpc-info.sh $CLUSTERNAME
