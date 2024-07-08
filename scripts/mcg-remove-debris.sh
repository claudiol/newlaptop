#!/bin/sh

ARGOPROJ=$(oc get --show-kind --ignore-not-found -n openshift-gitops argocds.argoproj.io | grep -v NAME | awk '{print $1}')
if [ ! -z $ARGOPROJ ]; then
  echo #   oc delete $ARGOPROJ -n openshift-gitops
fi

#
# Removing OpenShift GitOps subs
#
SUB=$(oc get sub -n openshift-operator | grep openshift-gitops | awk '{print $1}' | xargs oc delete -n openshift-operator)
CSV=$(oc get csv -n openshift-operator | grep openshift-gitops | awk '{print $1}' | xargs oc delete -n openshift-operator)


oc get replicasets -n openshift-gitops | grep -v NAME | awk '{print $1}' | xargs oc delete replicaset
oc get deployments -n openshift-gitops | grep -v NAME | awk '{print $1}' | xargs oc delete deployment
oc get service -n openshift-gitops | grep -v NAME | awk '{print $1}' | xargs oc delete service
oc get pods -n openshift-gitops | grep -v NAME | awk '{print $1}' | xargs oc delete pod

oc get sts -n openshift-gitops | grep -v NAME | awk '{print $1}' | xargs oc delete sts
