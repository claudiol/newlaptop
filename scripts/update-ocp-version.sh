#!/bin/sh


CURRENTDIR=$(pwd)
FAST=0

cd /tmp

while getopts "fv:" opt
do
    case $opt in
	(v) VERSION=$OPTARG
	    ;;
	(f) FAST=1
	    ;;
	(*) printf "Illegal option '-%s'\n" "$opt" && exit 1
            exit
	    ;;
    esac
done

if [ -z $VERSION ]; then
	echo "Need a OCP version"
	echo "$0 -v 4.12"
	exit
fi

echo "Getting the latest stable [$VERSION] binaries for OpenShift"

if [ $FAST -eq 1 ] && [ ! -d ~/bin/ocpfast-$VERSION ]; then
  mkdir -p ~/bin/ocpfast-$VERSION
fi

if [ ! -d ~/bin/ocp$VERSION ]; then
  mkdir -p ~/bin/ocp$VERSION
fi

if [ $FAST -eq 1 ]; then
  echo "Retrieving oc-mirror"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$VERSION/oc-mirror.tar.gz
  echo "Extracting oc-mirror"
  tar -C ~/bin/ocpfast-$VERSION -xvf oc-mirror.tar.gz
  echo "Removing oc-mirror archive"
  rm -f oc-mirror.tar.gz
  
  echo "Retrieving oc CLI"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$VERSION/openshift-client-linux.tar.gz
  echo "Extracting oc CLI"
  tar -C ~/bin/ocpfast-$VERSION -xvf openshift-client-linux.tar.gz
  echo "Removing oc CLI archive"
  rm -f openshift-client-linux.tar.gz
  
  echo "Retrieving openshift-install installer"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$VERSION/openshift-install-linux.tar.gz
  echo "Extracting openshift installer"
  tar -C ~/bin/ocpfast-$VERSION -xvf openshift-install-linux.tar.gz
  echo "Removing openshift installer archive"
  rm -f openshift-install-linux.tar.gz
else
  echo "Retrieving oc-mirror"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$VERSION/oc-mirror.tar.gz
  echo "Extracting oc-mirror"
  tar -C ~/bin/ocp$VERSION -xvf oc-mirror.tar.gz
  echo "Removing oc-mirror archive"
  rm -f oc-mirror.tar.gz
  
  echo "Retrieving oc CLI"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$VERSION/openshift-client-linux.tar.gz
  echo "Extracting oc CLI"
  tar -C ~/bin/ocp$VERSION -xvf openshift-client-linux.tar.gz
  echo "Removing oc CLI archive"
  rm -f openshift-client-linux.tar.gz
  
  echo "Retrieving openshift-install installer"
  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$VERSION/openshift-install-linux.tar.gz
  echo "Extracting openshift installer"
  tar -C ~/bin/ocp$VERSION -xvf openshift-install-linux.tar.gz
  echo "Removing openshift installer archive"
  rm -f openshift-install-linux.tar.gz
fi
cd $CURRENTDIR

