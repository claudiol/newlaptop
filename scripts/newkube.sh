#!/bin/sh
#
FOUND=0
DIR=$(ls -d ~/work/clusters/*$1-* 2>&1 | grep -v log)
if [[ "$DIR" != *"cannot access"* ]] && [ "$DIR." != "." ] && [ -d $DIR ]; then
   if [[ "$DIR" == *"HYPERSHIFT"* ]]; then
     export KUBECONFIG=$DIR/kubeconfig
     echo $KUBECONFIG
     export KUBEPASS=$(cat $DIR/kubeadmin-password)
     echo $KUBEPASS
     export CURRENT_CLUSTER_DIR=$DIR
     if [[ ":$PATH:" == *":$DIR:"* ]]; then
       echo "Your path is correctly set"
     else
       export PATH=$DIR:$PATH
     fi
     FOUND=1
   else
     export KUBECONFIG=$DIR/auth/kubeconfig
     echo $KUBECONFIG
     export KUBEPASS=$(cat $DIR/auth/kubeadmin-password)
     echo $KUBEPASS
     export CURRENT_CLUSTER_DIR=$DIR
     FOUND=1
   fi
fi

if [ $FOUND -eq 0 ]; then
  VPDIR=$(ls -d ~/work/clusters/ocp_install/*$1* 2>&1 | grep -v log )
  echo $VPDIR
  if [[ "$VPDIR" != *"cannot access"* ]] && [ "$VPDIR." != "." ] && [ -d $VPDIR ]; then
     export KUBECONFIG=$VPDIR/auth/kubeconfig
     echo $KUBECONFIG
     export KUBEPASS=$(cat $VPDIR/auth/kubeadmin-password)
     echo $KUBEPASS
  fi
fi
