#!/bin/bash
#

if [ -z $KUBECONFIG ] || [ -z $KUBEPASS ]; then
  echo "Need KUBECONFIG and KUBEADMINPASS ..."
  exit
fi

if [ -z $IIB ]; then
   while [ -z $IIB ]; do
      echo "Please enter IIB Number"
      read iib
      if [[ $iib ]] && [ $iib -eq $iib 2>/dev/null ]
      then
        IIB=$iib
      else
        echo "The IIB $iib is not an integer or not defined"
      fi
   done
fi

OPENSHIFT_MIN_VERSION=$(oc get clusterversion  | grep -v NAME | awk '{print $2}' | cut -d '.' -f 2)

if [ $OPENSHIFT_MIN_VERSION -lt 13 ]; then
  export REGISTRY=quay.io/claudiol/iib
  export REGISTRY_TOKEN=claudiol+ops:BMF9S4ATHO920SCLN436X5PYQULIC8VEEHR4EKM3BRL2KYS3DS3J6G51ER9888NF
fi

# export KUBECONFIG=/tmp/foo/kubeconfig
#export IIB=610968
export OPERATOR=openshift-gitops-operator
export IIB=$iib
export INDEX_IMAGES=registry-proxy.engineering.redhat.com/rh-osbs/iib:${IIB}
export KUBEADMINPASS="$KUBEPASS"


make load-iib
