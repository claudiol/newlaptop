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

if [[ -z "${KUBECONFIG}" ]]; then
    log "Please set KUBECONFIG to connecto to OpenShift"
    exit
else
    log "Using [$KUBECONFIG] to connect to OpenShift"
fi


while ( true )
do
  log -n "Waiting for routes #    "
  sleep .5
  oc get routes -n openshift-console > /dev/null 2>&1
  log -n "Waiting for routes ##   "
  sleep .5
  if [ $? == 0 ]; then
    CLEAN=$(oc get routes -n openshift-console 2>&1 | grep -v error | grep -i console )
    if [ "$CLEAN." != "." ]; then
        echo "You should be able to get to the OpenShift console using the following routes"
        oc get routes -n openshift-console
        break
    else
        continue
    fi
  fi
  sleep .5
  log -n "Waiting for routes ###  "
  sleep 1
  log -n "Waiting for routes      "
  sleep 1
done

