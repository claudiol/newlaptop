#!/bin/sh

DATACENTER=0
FACTORY=0
GITOPS=0
MCG=0
while getopts "pdfgmw:" opt
do
    case $opt in
        (d) DATACENTER=1
            ;;
        (f) FACTORY=1
            ;;
        (m) MCG=1
	    ;;
        (p) PATTERN=1
            ;;
        (g) GITOPS=1
            ;;
	(w) WILDCARD=$OPTARG
	    ;;
        (*) printf "Illegal option '-%s'\n" "$opt" && exit 1
            ;;
    esac
done
PATTERN_NAME=$(oc get pattern -n openshift-operators -o json | jq '.items[].metadata.name' | tr -d '"')
REPOBASE=$(basename $(git rev-parse --show-toplevel))
oc projects | grep $(basename $(git rev-parse --show-toplevel))
if [ $GITOPS -eq 1 ]; then
  argocd login $(oc get routes -n openshift-gitops openshift-gitops-server -o=jsonpath='{ .spec.host }') --sso
elif [ $DATACENTER -eq 1 ]; then
  argocd login $(oc get routes -n industrial-edge-datacenter datacenter-gitops-server -o=jsonpath='{ .spec.host }') --sso
elif [ $FACTORY -eq 1 ]; then
  argocd login $(oc get routes -n openshift-gitops openshift-gitops-server -o=jsonpath='{ .spec.host }') --sso
elif [ $MCG -eq 1 ]; then
  argocd login $(oc get routes -n multicloud-gitops-hub hub-gitops-server -o=jsonpath='{ .spec.host }') --sso
elif [ $PATTERN -eq 1 ]; then
  argocd login $(oc get routes -n $PATTERN_NAME-hub hub-gitops-server -o=jsonpath='{ .spec.host }') --sso
elif [ ".$WILDCARD" != "."  ]; then
  argocd login $(oc get routes -n multicluster-devsecops-development $WILDCARD -o=jsonpath='{ .spec.host }') --sso
fi

