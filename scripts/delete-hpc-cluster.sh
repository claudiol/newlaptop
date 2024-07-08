#!/bin/sh

CLUSTERDIR=/home/claudiol/work/clusters
FIPS=0
XRAY=0

usage() {
  printf "$0 -n <CLUSTER-NAME>\n"
  exit 1
}

while getopts "n:" opt
do
    case $opt in
	(n) if [[ "$OPTARG" == *","* ]]; then
	      CLUSTERNAME=$(echo $* | sed "s|-n||g" ) # option to list multiple clusters e.g. cluster1, cluster2,cluster3
		else
	      CLUSTERNAME=$OPTARG
		fi
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" 
	    usage
	    ;;
    esac
done

if [ "$CLUSTERNAME." == "." ]; then
	usage
	exit
fi

INFRAID=$(oc get -o jsonpath='{.spec.infraID}'  hostedcluster $CLUSTERNAME -n clusters )

if [ ! -z $KUBECONFIG ]; then
    unset KUBECONFIG
fi
#hypershift destroy cluster aws --aws-creds ~/.aws/credentials --base-domain aws.validatedpatterns.io --region $(cat $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-region) --destroy-cloud-resources --name $CLUSTERNAME --infra-id $(cat $CLUSTERDIR/$REGION-$CLUSTERNAME-HYPERSHIFT/cluster-infraid)
RC=$(hypershift destroy cluster aws --name $CLUSTERNAME --base-domain aws.validatedpatterns.io --aws-creds ~/.aws/credentials --region $REGION --destroy-cloud-resources --infra-id $INFRAID; echo $?)
if [ $RC -ne 0 ]; then
  echo "Error destroying $CLUSTERNAME"
else
  echo "Success"
fi
