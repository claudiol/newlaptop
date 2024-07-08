#!/bin/sh

oc project $1
DEX=$(oc get deploy | grep dex | awk '{print $1}')
oc patch deploy/${DEX} --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/securityContext/runAsNonRoot", "value": 'false'}]' -n $1 
