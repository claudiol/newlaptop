#!/bin/bash

CLUSTERNAME=""

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

if [ -z $1 ]; then
  NAMESPACES=$(oc get namespaces | grep Terminating | awk '{print $1}')
else 
  NAMESPACES=$1
fi

oc proxy&
PID=`ps | grep oc | awk '{print $1}'`
echo $PID
cd /tmp
sleep 2
for i in $NAMESPACES
do
   log -n "Terminating $i ..."
   oc get namespace $i -o yaml | sed 's|- kubernetes||g' > /tmp/$i-terminate-ns.yaml
   curl -k -H "Content-Type: application/yaml" -X PUT --data-binary @$i-terminate-ns.yaml http://127.0.0.1:8001/api/v1/namespaces/$i/finalize > /dev/null 2>&1
   rm -f /tmp/$i-terminate-ns.yaml
   echo "done"
done
kill -9 $PID

