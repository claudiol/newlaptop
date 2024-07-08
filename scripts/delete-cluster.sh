#!/bin/sh

CLUSTERDIR=/home/claudiol/work/clusters
FIPS=0
XRAY=0
INSTALL_CONFIG_FILE=datacenter-blueprints-install-config.yaml

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

MULTICLUSTER=$(echo $CLUSTERNAME | tr -d ' ' | grep ',')

if [ ".$MULTICLUSTER" == "." ]; then
  echo "Checking for directory ..."
  cd $CLUSTERDIR
  CLUSTERLOCALDIR=$(ls | grep $CLUSTERNAME | grep -v log)
  
  if [ -d $CLUSTERDIR/$CLUSTERLOCALDIR ]; then
      echo "Existing $CLUSTERDIR/$CLUSTERLOCALDIR directory. "
	  echo "Running openshift-install destroy cluster --dir $CLUSTERDIR/$CLUSTERLOCALDIR"
	  openshift-install destroy cluster --dir $CLUSTERDIR/$CLUSTERLOCALDIR
	  echo "Removing $CLUSTERDIR/$CLUSTERLOCALDIR"
	  if [ ! -z $CLUSTERLOCALDIR ]; then
	    rm -rf $CLUSTERDIR/$CLUSTERLOCALDIR
	  fi
	  echo "done"
  else
      echo "Cluster directory $CLUSTERDIR/$CLUSTERLOCALDIR directory does not exist. "
	  exit
  fi
  cd -
else
  CLUSTERS=$(echo $MULTICLUSTER | sed "s/,/ /g")
  echo $CLUSTERS
  for i in $CLUSTERS
  do
    
    echo "Checking for directory ..."
    cd $CLUSTERDIR
    CLUSTERLOCALDIR=$(ls | grep $i | grep -v log)
  
    if [ "$CLUSTERLOCALDIR." == "." ]; then
	   echo "$i does not exist"
	elif [ -d $CLUSTERDIR/$CLUSTERLOCALDIR ]; then
        echo "Existing $CLUSTERDIR/$CLUSTERLOCALDIR directory. "
	    echo "Running openshift-install destroy cluster --dir $CLUSTERDIR/$CLUSTERLOCALDIR"
	    openshift-install destroy cluster --dir $CLUSTERDIR/$CLUSTERLOCALDIR
	    echo "Removing $CLUSTERDIR/$CLUSTERLOCALDIR"
		if [ ! -z $CLUSTERLOCALDIR ]; then
	      rm -rf $CLUSTERDIR/$CLUSTERLOCALDIR
		fi
	    echo "done"
    else
        echo "Cluster directory $CLUSTERDIR/$CLUSTERLOCALDIR directory does not exist. "
	    exit
    fi
    cd -
  done
fi
