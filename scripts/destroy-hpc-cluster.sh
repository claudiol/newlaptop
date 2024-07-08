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

CLUSTERNAME=$1

INFRAID=$(oc get -o jsonpath='{.spec.infraID}'  hostedcluster $CLUSTERNAME -n clusters)

hypershift destroy cluster aws --aws-creds ~/.aws/credentials --base-domain aws.validatedpatterns.io --region us-west-2 --destroy-cloud-resources --name $CLUSTERNAME --infra-id $INFRAID

if [ $? -eq 0 ]; then
  echo "Success"
fi

