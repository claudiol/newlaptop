#!/bin/sh
#

CLUSTERDIR=/home/claudiol/work/clusters
if [ -f $CURRENT_CLUSTER_DIR/cluster-region ]; then
  REGION=$(cat $CURRENT_CLUSTER_DIR/cluster-region)
else
  REGION=us-west-2
  echo $REGION > $CURRENT_CLUSTER_DIR/cluster-region
fi



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

if [ "$1." == "." ]; then
  log "Need a cluster name"
  exit
fi
CLUSTERNAME=$1

log -n "Checking kubeconfig is unset ... "
if [ ! -z $KUBECONFIG ]; then
  unset KUBECONFIG
fi
echo "done."

RC=$(oc whoami > /dev/null 2>&1;echo $?)
if [ $RC -ne 0 ]; then
  log "Make sure you are logged in to the hypershift console"
  log "Visit: https://console-openshift-console.apps.hcp.blueprints.rhecoeng.com/"
  exit
else   
  USER=$(oc whoami)
  log "Logged in as $USER"
fi


STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $5 }')
if [ "$STATUS" == "False" ] || [ "$STATUS" == "True" ]; then
  STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $4 }')
  if [ "$STATUS" == "False" ]; then
    STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $3 }')
  fi
fi
echo $STATUS
log -n "Checking cluster $CLUSTERNAME "
while [[ $STATUS == *"Partial"* ]]; do
  log -n "Cluster $CLUSTERNAME is not ready #         "
  sleep 2
  STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $5 }')
  if [ "$STATUS" == "False" ] || [ "$STATUS" == "True" ]; then
    STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $4 }')
    if [ "$STATUS" == "False" ] || [ "$STATUS" == "True" ]; then
      STATUS=$(oc get hostedclusters.hypershift.openshift.io -A | grep $CLUSTERNAME | awk '{ print $3 }')
    fi
  fi
  log -n "Cluster $CLUSTERNAME is not ready ###"
  sleep 2
done
log "Cluster $CLUSTERNAME is ready                   "

log -n "Creating kubeconfig for $CLUSTERNAME ... "
RC=$(hypershift create kubeconfig --name $CLUSTERNAME > $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/kubeconfig; echo $?)
if [ $RC -eq 0 ]; then
  echo "done."
else
  echo "ERROR"
fi

log -n "Creating kubeadmin-password ... "
#oc project clusters-$CLUSTERNAME
RC=$(oc extract secret/kubeadmin-password -n clusters-$CLUSTERNAME --keys=password --to=- > $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/kubeadmin-password 2>&1; echo $?)
if [ $RC -eq 0 ]; then
  echo "done"
else
  echo "ERROR"
fi

RC=$(oc get -o jsonpath='{.spec.infraID}'  hostedcluster $CLUSTERNAME -n clusters > $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-infraid; echo $?)

if [ $RC -eq 0 ]; then
  echo "done"
else
  echo "ERROR"
fi

log -n "Creating destroy script ... "
cat <<EOF > $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/destroy-$CLUSTERNAME.sh
#!/bin/bash
#
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

if [ ! -z $KUBECONFIG ]; then
  log -n "Unsetting KUBECONFIG environment variable ... "
  unset KUBECONFIG
  echo "done."
fi

hypershift destroy cluster aws --aws-creds ~/.aws/credentials --base-domain aws.validatedpatterns.io --region $(cat $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-region) --destroy-cloud-resources --name $CLUSTERNAME --infra-id $(cat $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-infraid)

if [ \$? -eq 0 ]; then
  echo "Success"
fi
log -n "Deleting cluster for good ..."

~/bin/destroy-hpc-cluster.sh $CLUSTERNAME

if [ \$? -eq 0 ]; then
  echo "Success"

  # Remove the directory if successful
  if [ -d $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT ]; then
    log -n "Removing [$CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT] ... "
    rm -rf $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT
    echo "done."
  fi
fi

EOF
chmod +x $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/destroy-$CLUSTERNAME.sh
echo "done."

