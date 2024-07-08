#!/bin/sh
#
#

function log {
    if [ -z "$2" ]; then
        echo -e "\033[0K\r\033[1;36m$1\033[0m"
    else
        echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
    fi
}

function retrieveNameSpaceForSub () {
  NS=$(oc get sub -A | grep $SUB | awk '{print $1}')

  if [ "$NS." == "." ]; then
    log "Could not find subscription for $SUB"
	exit
  fi
  return 0
}

function checkSubscriptionStatus () {
  SUB=$1
  retrieveNameSpaceForSub 
  OUTPUT=$(oc get sub/$1 -n $NS -o json | jq .status.state)
  if [ $? -eq 0 ]; then
    if [[ "$OUTPUT" == *"AtLatestKnown"* ]]; then
	  log "At Subscription is in $OUTPUT state"
	  return 0
    else
	  log "Subscription is in $OUTPUT state"
	  return 1
	fi
  else
    log "Subscription is in $OUTPUT state"
	return 1
  fi

}
function fixUpgradeIssue() {
  for i in `oc get job -n openshift-marketplace -o json | jq -r '.items[] | select(.spec.template.spec.containers[].env[].value|contains ("$1")) | .metadata.name'`
  do
     oc delete job $i -n openshift-marketplace
     oc delete configmap $i -n openshift-marketplace
  done
}


checkSubscriptionStatus $1 
if [ $? -eq 0 ]; then
  log "Subscription ok"
else
  fixUpgradeIssue rhacm
fi
